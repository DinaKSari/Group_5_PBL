import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/core/failures.dart';
import 'package:smart_farming/core/session.dart';
import 'package:smart_farming/features/prediction/domain/entities/parameter_spec.dart';
import 'package:smart_farming/features/sensor/data/models/sensor_entry_model.dart';
import 'package:smart_farming/features/sensor/data/repositories/http_sensor_repository.dart';
import 'package:smart_farming/features/sensor/domain/entities/sensor_entry.dart';
import 'package:smart_farming/features/sensor/domain/repositories/sensor_repository.dart';
import 'package:smart_farming/features/sensor/presentation/pages/sensor_entry_page.dart';
import 'package:smart_farming/features/sensor/presentation/providers/sensor_providers.dart';

/// Entri lengkap memakai nilai default spesifikasi — jadi angka yang diuji
/// selalu mengikuti satu sumber kebenaran, tidak ditulis dua kali.
final _completeEntry = SensorEntry({
  for (final spec in kGrowthParameters) spec.key: spec.defaultValue,
}, lokasi: 'Bedeng 3');

class _StubClient extends http.BaseClient {
  _StubClient(this.status, this.body);

  final int status;
  final String body;

  Map<String, dynamic>? sent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent = jsonDecode(
      await request.finalize().transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _ThrowingClient extends http.BaseClient {
  _ThrowingClient(this.error);

  final Object error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      throw error;
}

class _RecordingRepository implements SensorRepository {
  final List<SensorEntry> calls = [];
  Failure? result;

  @override
  Future<Failure?> record(SensorEntry entry) async {
    calls.add(entry);
    return result;
  }
}

void main() {
  setUp(() {
    Session.clear();
    Session.uid = 'user-test';
  });

  group('SensorEntry & SensorEntryModel', () {
    test('isComplete menolak nilai di luar rentang spesifikasi', () {
      expect(_completeEntry.isComplete, isTrue);

      final terlaluTua = SensorEntry({
        ..._completeEntry.values,
        'umur_hst': 60,
      });
      expect(terlaluTua.isComplete, isFalse);
      expect(
        SensorEntry({..._completeEntry.values}..remove('ph')).isComplete,
        isFalse,
      );
    });

    test('toMap memakai nama kolom kontrak ML + sumber manual', () {
      final body = SensorEntryModel(_completeEntry).toMap();

      for (final spec in kGrowthParameters) {
        expect(body.containsKey(spec.key), isTrue, reason: spec.key);
      }
      expect(body['source'], 'manual');
      expect(body['lokasi'], 'Bedeng 3');
    });

    test('lokasi kosong tidak dikirim (server yang mengisi default)', () {
      final body = SensorEntryModel(
        SensorEntry(_completeEntry.values, lokasi: '  '),
      ).toMap();

      expect(body.containsKey('lokasi'), isFalse);
    });
  });

  group('HttpSensorRepository.record', () {
    test('mode Tamu ditahan sebelum ada request keluar', () async {
      Session.isGuest = true;
      final client = _StubClient(201, '{}');

      final failure = await HttpSensorRepository(client: client)
          .record(_completeEntry);

      expect(failure, isA<AuthFailure>());
      expect(client.sent, isNull);
    });

    test('nilai tidak lengkap tidak dikirim ke server', () async {
      final client = _StubClient(201, '{}');

      final failure = await HttpSensorRepository(client: client)
          .record(SensorEntry({..._completeEntry.values, 'suhu': 99}));

      expect(failure, isA<LocalFailure>());
      expect(client.sent, isNull);
    });

    test('POST /api/sensor mengirim body lengkap dan 201 = sukses', () async {
      final client = _StubClient(201, '{"data":{"id":7}}');

      final failure = await HttpSensorRepository(client: client)
          .record(_completeEntry);

      expect(failure, isNull);
      expect(client.sent!['umur_hst'], 20);
      expect(client.sent!['ph'], 6.0);
      expect(client.sent!['source'], 'manual');
    });

    test('422 Laravel: pesan validasi ikut sampai ke perangkat', () async {
      final client = _StubClient(
        422,
        '{"message":"The given data was invalid.","errors":{"ph":["The ph must be between 4 and 9."]}}',
      );

      final failure = await HttpSensorRepository(client: client)
          .record(_completeEntry);

      expect(failure, isA<ServerFailure>());
      expect(failure!.message, contains('must be between 4 and 9'));
    });

    test('401 = AuthFailure, sesi user memang sudah habis', () async {
      final client = _StubClient(401, '{"message":"Unauthenticated."}');

      final failure = await HttpSensorRepository(client: client)
          .record(_completeEntry);

      expect(failure, isA<AuthFailure>());
    });

    test('backend mati -> NetworkFailure, bukan exception mentah', () async {
      final repository = HttpSensorRepository(
        client: _ThrowingClient(const SocketException('Connection refused')),
      );

      expect(await repository.record(_completeEntry), isA<NetworkFailure>());
    });

    test('server menggantung -> ServerFailure berbatas waktu', () async {
      final repository = HttpSensorRepository(
        client: _ThrowingClient(TimeoutException('lambat')),
      );

      expect(await repository.record(_completeEntry), isA<ServerFailure>());
    });
  });

  group('SensorEntryPage', () {
    late _RecordingRepository repository;

    setUp(() => repository = _RecordingRepository());

    Future<GoRouter> pumpPage(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/isi',
            builder: (context, state) => const SensorEntryPage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sensorRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      // Halaman ini selalu dibuka lewat push dari dashboard, supaya context.pop()
      // setelah simpan menemukan rute di bawahnya seperti di aplikasi nyata.
      router.push('/isi');
      await tester.pumpAndSettle();
      return router;
    }

    // Tombol simpan berada di bawah lipatan pada viewport tes 800x600.
    Future<void> tapSave(WidgetTester tester) async {
      final button = find.widgetWithText(FilledButton, 'Simpan Catatan');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('nilai default spesifikasi terkirim apa adanya', (
      tester,
    ) async {
      final router = await pumpPage(tester);

      await tapSave(tester);

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.isComplete, isTrue);
      // Entri sukses -> halaman ditutup, user kembali ke dashboard.
      expect(
        router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        '/',
      );
    });

    testWidgets('angka di luar rentang ditahan di perangkat, tidak dikirim', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Suhu (°C)'),
        '250',
      );
      await tapSave(tester);

      expect(find.textContaining('Suhu harus di antara'), findsOneWidget);
      expect(repository.calls, isEmpty);
    });

    testWidgets('kegagalan server ditampilkan, halaman tidak ditutup', (
      tester,
    ) async {
      final router = await pumpPage(tester);
      repository.result = const ServerFailure('Koneksi ke database gagal.');

      await tapSave(tester);

      expect(find.text('Koneksi ke database gagal.'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches.length, 2);
    });
  });
}
