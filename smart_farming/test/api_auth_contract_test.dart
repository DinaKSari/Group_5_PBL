import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/core/api_client.dart';
import 'package:smart_farming/core/failures.dart';
import 'package:smart_farming/core/session.dart';
import 'package:smart_farming/features/history/data/repositories/http_history_repository.dart';
import 'package:smart_farming/features/home/data/monitoring_service.dart';
import 'package:smart_farming/features/prediction/data/repositories/http_prediction_repository.dart';
import 'package:smart_farming/features/prediction/domain/entities/prediction_request.dart';

/// Mencatat request yang lewat dan membalas status/body tetap.
class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.status, this.body, {this.contentType = 'application/json'});

  final int status;
  final String body;
  final String contentType;

  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': contentType},
    );
  }
}

const _predictPayload = PredictionRequest(
  plantAge: 20,
  temperature: 23,
  humidity: 75,
  tds: 700,
  ph: 6,
);

void main() {
  setUp(() => Session.clear());

  group('ApiClient header identitas', () {
    test('memakai ID token dari supplier, bukan user_uid di body', () async {
      final stub = _RecordingClient(201, '{"days_left":25}');
      final api = ApiClient(client: stub, idToken: () async => 'id-token-abc');

      await api.postJson('/predict', {
        'umur_hst': 20,
        'suhu': 23.0,
        'kelembapan': 75,
        'tds': 700,
        'ph': 6.0,
      });

      final request = stub.requests.single as http.Request;
      expect(request.headers['Authorization'], 'Bearer id-token-abc');
      expect(request.headers['ngrok-skip-browser-warning'], isNotNull);
      expect(jsonDecode(request.body).containsKey('user_uid'), isFalse);
    });

    test('tanpa sesi: tidak ada header Authorization', () async {
      final stub = _RecordingClient(401, '{"message":"Sesi tidak valid."}');
      final api = ApiClient(client: stub, idToken: () async => null);

      final response = await api.get('/predictions');

      expect(stub.requests.single.headers['Authorization'], isNull);
      expect(response.statusCode, 401);
    });

    test('401 membersihkan sesi dan menaikkan notifier', () async {
      Session.uid = 'uid-1';
      final bumpedBefore = sessionExpiredNotifier.value;
      final api = ApiClient(
        client: _RecordingClient(401, '{}'),
        idToken: () async => 'kadaluarsa',
      );

      await api.get('/predictions');

      expect(Session.uid, isNull);
      expect(sessionExpiredNotifier.value, greaterThan(bumpedBefore));
    });

    test('jsonBody menolak HTML (halaman ngrok saat backend mati)', () {
      final html = http.Response('<html>502 Bad Gateway</html>', 502,
          headers: {'content-type': 'text/html'});
      expect(ApiClient.jsonBody(html), isNull);
    });
  });

  group('Mode Tamu read-only (RUNBOOK R1)', () {
    test('riwayat tidak pernah diminta ke server', () async {
      Session.isGuest = true;
      final stub = _RecordingClient(200, '{"data":[]}');

      final outcome = await HttpHistoryRepository(client: stub).getHistory();

      expect(stub.requests, isEmpty);
      expect(outcome.items, isEmpty);
      expect(outcome.failure, isA<AuthFailure>());
    });

    test('prediksi ditolak dengan saran masuk, tanpa POST', () async {
      Session.isGuest = true;
      final stub = _RecordingClient(201, '{"days_left":25}');

      final outcome = await HttpPredictionRepository(client: stub).predict(_predictPayload);

      expect(stub.requests, isEmpty);
      expect(outcome.result, isNull);
      expect(outcome.failure, isA<AuthFailure>());
    });

    test('dashboard kosong tanpa panggilan jaringan', () async {
      Session.isGuest = true;
      final stub = _RecordingClient(200, '{"data":null}');

      final data = await MonitoringService(client: stub).fetch();

      expect(stub.requests, isEmpty);
      expect(data.isEmpty, isTrue);
      expect(data.failure, contains('Masuk'));
    });
  });

  group('HttpHistoryRepository kontrak kegagalan', () {
    test('server mati dilaporkan sebagai kegagalan, bukan daftar kosong diam-diam', () async {
      Session.uid = 'uid-1';

      final outcome = await HttpHistoryRepository(
        client: _ThrowingClient(const SocketException('refused')),
      ).getHistory();

      expect(outcome.failure, isA<NetworkFailure>());
    });

    test('respons HTML (bukan JSON) menjadi ServerFailure', () async {
      Session.uid = 'uid-1';

      final outcome = await HttpHistoryRepository(
        client: _RecordingClient(200, '<html/>', contentType: 'text/html'),
      ).getHistory();

      expect(outcome.failure, isA<ServerFailure>());
    });
  });
}

class _ThrowingClient extends http.BaseClient {
  _ThrowingClient(this.error);
  final Object error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async => throw error;
}
