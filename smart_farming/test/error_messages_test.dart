import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/core/error_messages.dart';
import 'package:smart_farming/core/failures.dart';
import 'package:smart_farming/core/session.dart';
import 'package:smart_farming/features/history/data/repositories/http_history_repository.dart';
import 'package:smart_farming/features/prediction/domain/entities/parameter_spec.dart';
import 'package:smart_farming/features/sensor/data/repositories/http_sensor_repository.dart';
import 'package:smart_farming/features/sensor/domain/entities/sensor_entry.dart';

class _StubResponse extends http.BaseClient {
  _StubResponse(this.status, this.body, this.contentType);

  final int status;
  final String body;
  final String contentType;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        status,
        headers: {'content-type': contentType},
      );
}

http.Response _response(int status, String body, String contentType) =>
    http.Response(body, status, headers: {'content-type': contentType});

/// Semua kalimat yang boleh dilihat pengguna, untuk diperiksa serentak.
const _semuaKalimat = [
  ErrorMessages.offline,
  ErrorMessages.network,
  ErrorMessages.sessionExpired,
  ErrorMessages.forbidden,
  ErrorMessages.notFound,
  ErrorMessages.serverBusy,
  ErrorMessages.tooOften,
  ErrorMessages.checkInput,
  ErrorMessages.unexpected,
];

void main() {
  group('ErrorMessages.fromResponse', () {
    test('HTML 404 dari ngrok = server mati, bukan "Status 404"', () {
      expect(
        ErrorMessages.fromResponse(
            _response(404, '<html>session not found</html>', 'text/html')),
        ErrorMessages.offline,
      );
    });

    test('HTML 502 = server bermasalah, tetap tanpa angka status', () {
      final pesan = ErrorMessages.fromResponse(
          _response(502, '<html>Bad Gateway</html>', 'text/html'));
      expect(pesan, ErrorMessages.serverBusy);
      expect(pesan, isNot(contains('502')));
    });

    test('JSON per status mendapat kalimatnya masing-masing', () {
      const json = 'application/json';
      expect(ErrorMessages.fromResponse(_response(401, '{}', json)),
          ErrorMessages.sessionExpired);
      expect(ErrorMessages.fromResponse(_response(403, '{}', json)),
          ErrorMessages.forbidden);
      expect(ErrorMessages.fromResponse(_response(404, '{}', json)),
          ErrorMessages.notFound);
      expect(ErrorMessages.fromResponse(_response(422, '{}', json)),
          ErrorMessages.checkInput);
      expect(ErrorMessages.fromResponse(_response(429, '{}', json)),
          ErrorMessages.tooOften);
      expect(ErrorMessages.fromResponse(_response(500, '{}', json)),
          ErrorMessages.serverBusy);
      expect(ErrorMessages.fromResponse(_response(418, '{}', json)),
          ErrorMessages.unexpected);
    });
  });

  group('ErrorMessages.fromException', () {
    test('timeout dianggap server yang belum menjawab', () {
      expect(ErrorMessages.fromException(TimeoutException('telat')),
          ErrorMessages.offline);
    });

    test('socket gagal dianggap koneksi pengguna', () {
      final socket = SocketException('failed host lookup');
      expect(ErrorMessages.fromException(socket), ErrorMessages.network);
    });

    test('exception lain tidak menampilkan teks aslinya ke layar', () {
      expect(ErrorMessages.fromException(StateError('NaN di jsonEncode')),
          ErrorMessages.unexpected);
    });
  });

  test('kalimat pengguna bebas angka status dan istilah teknis', () {
    final teknis = RegExp(
        r'[0-9]|HTTP|status|exception|socket|timeout|backend|laravel|flask|api',
        caseSensitive: false);
    for (final kalimat in _semuaKalimat) {
      expect(kalimat, isNot(matches(teknis)), reason: kalimat);
      expect(kalimat.length, greaterThan(12), reason: kalimat);
    }
  });

  test('Riwayat tidak bisa lagi memunculkan "Status 404"', () async {
    Session.isGuest = false;
    final repo = HttpHistoryRepository(
        client: _StubResponse(404, '<html>no agent</html>', 'text/html'));

    final out = await repo.getHistory();

    expect(out.failure, isA<ServerFailure>());
    expect(out.failure!.message, ErrorMessages.offline);
  });

  test('Riwayat memprioritaskan pesan 401 apa adanya', () async {
    Session.isGuest = false;
    final repo = HttpHistoryRepository(
        client: _StubResponse(401, '{"message":"Unauthenticated."}',
            'application/json'));

    final out = await repo.getHistory();

    expect(out.failure, isA<AuthFailure>());
    expect(out.failure!.message, ErrorMessages.sessionExpired);
  });

  test('Sensor 500 dengan "Server Error" Inggris diganti kalimat kita', () async {
    Session.isGuest = false;
    final repo = HttpSensorRepository(
        client: _StubResponse(
            500, '{"message":"Server Error"}', 'application/json'));
    final entry = SensorEntry({
      for (final spec in kGrowthParameters) spec.key: spec.defaultValue,
    }, lokasi: 'Bedeng 1');

    final failure = await repo.record(entry);

    expect(failure, isA<ServerFailure>());
    expect(failure!.message, ErrorMessages.serverBusy);
  });

  test('Sensor 422 tetap menampilkan pesan kolom dari Laravel', () async {
    Session.isGuest = false;
    final repo = HttpSensorRepository(
        client: _StubResponse(
            422,
            '{"message":"The selected ph is invalid.","errors":{"ph":["pH harus antara 4 dan 9"]}}',
            'application/json'));
    final entry = SensorEntry({
      for (final spec in kGrowthParameters) spec.key: spec.defaultValue,
    }, lokasi: 'Bedeng 1');

    final failure = await repo.record(entry);

    expect(failure!.message, 'pH harus antara 4 dan 9');
  });
}
