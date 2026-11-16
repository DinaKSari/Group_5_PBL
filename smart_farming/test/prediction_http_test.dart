import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farming/core/failures.dart';
import 'package:smart_farming/features/prediction/data/repositories/http_prediction_repository.dart';
import 'package:smart_farming/features/prediction/domain/entities/prediction_request.dart';

class _StubClient extends http.BaseClient {
  _StubClient(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
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

const _request = PredictionRequest(
  plantAge: 30,
  temperature: 27.5,
  humidity: 70,
  tds: 800,
  ph: 6.5,
);

/// Respons Laravel yang sudah digabung dengan payload mentah Flask.
const _successBody = '''
{
  "days_left": 15,
  "estimated_total_hst": 45,
  "harvest_date": "2026-11-27",
  "ready": false,
  "current_umur_hst": 30,
  "classification": {"growth_stage": "Vegetatif (Pembesaran)", "stage_id": 1},
  "clustering": {"cluster_id": 0, "profile": {"avg_suhu": 31.1, "count": 1295}},
  "features_used": {"umur_hst": 30, "suhu": 27.5, "kelembapan": 70, "tds": 800, "ph": 6.5},
  "id": 17,
  "lokasi": "Kebun"
}
''';

void main() {
  group('HttpPredictionRepository kontrak kegagalan', () {
    test('503 memakai pesan Laravel, bukan sekadar nomor status', () async {
      final repo = HttpPredictionRepository(
        client: _StubClient(
          503,
          jsonEncode({
            'message': 'Layanan prediksi ML tidak dapat dihubungi.',
          }),
        ),
      );

      final outcome = await repo.predict(_request);

      expect(outcome.result, isNull);
      expect(outcome.failure, isA<ServerFailure>());
      expect(
        outcome.failure!.message,
        'Layanan prediksi ML tidak dapat dihubungi.',
      );
    });

    test('422 menampilkan pesan per-field dari backend', () async {
      final repo = HttpPredictionRepository(
        client: _StubClient(
          422,
          jsonEncode({
            'message': 'The request body is invalid.',
            'errors': {
              'umur_hst': ['Umur tanaman harus antara 1 sampai 45 hari.'],
            },
          }),
        ),
      );

      final outcome = await repo.predict(_request);

      expect(
        outcome.failure!.message,
        contains('Umur tanaman harus antara 1 sampai 45 hari.'),
      );
    });

    test('backend mati menghasilkan NetworkFailure, tanpa data palsu', () async {
      final repo = HttpPredictionRepository(
        client: _ThrowingClient(
          const SocketException('connection refused'),
        ),
      );

      final outcome = await repo.predict(_request);

      expect(outcome.result, isNull);
      expect(outcome.failure, isA<NetworkFailure>());
    });

    test('timeout dilaporkan sebagai kegagalan, bukan hasil simulasi', () async {
      final repo = HttpPredictionRepository(
        client: _ThrowingClient(
          TimeoutException('predict', const Duration(seconds: 15)),
        ),
      );

      final outcome = await repo.predict(_request);

      expect(outcome.result, isNull);
      expect(outcome.failure, isNotNull);
    });

    test('201 dengan payload multi-task terparse menjadi hasil prediksi', () async {
      final repo = HttpPredictionRepository(
        client: _StubClient(201, _successBody),
      );

      final outcome = await repo.predict(_request);

      expect(outcome.failure, isNull);
      expect(outcome.result, isNotNull);
      expect(outcome.result!.daysLeft, 15);
    });
  });
}
