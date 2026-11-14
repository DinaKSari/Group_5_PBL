import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/prediction_request.dart';
import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../models/prediction_request_model.dart';
import '../models/prediction_result_model.dart';
import 'fake_prediction_repository.dart';

/// Implementasi repository prediksi riil melalui HTTP REST API (Flask / Laravel).
/// Jika server offline saat demo/testing lokal, otomatis fallback ke FakePredictionRepository
/// agar aplikasi tetap responsif.
class HttpPredictionRepository implements PredictionRepository {
  const HttpPredictionRepository({
    this._client,
    this.fallbackToFake = true,
  });

  final http.Client? _client;
  final bool fallbackToFake;

  static const _fallbackRepo = FakePredictionRepository();

  @override
  Future<({PredictionResult? result, Failure? failure})> predict(
    PredictionRequest request,
  ) async {
    final client = _client ?? http.Client();
    final url = Uri.parse('${ApiConfig.baseUrl}/predict');
    final payload = PredictionRequestModel(request).toMap();

    try {
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));

      // Laravel membalas 201 (store sukses); Flask lama membalas 200.
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PredictionResultModel.fromJson(data, DateTime.now());
        return (result: result, failure: null);
      }

      if (response.statusCode == 422) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final errors = data?['errors'];
        final msg = errors is List
            ? errors.join(', ')
            : errors is Map
                ? errors.values
                    .expand((e) => e is List ? e.map((x) => x.toString()) : [e.toString()])
                    .join(', ')
                : 'Validasi gagal.';
        return (result: null, failure: ServerFailure(msg));
      }

      return (
        result: null,
        failure: ServerFailure('Server mengembalikan status: ${response.statusCode}')
      );
    } on SocketException catch (e) {
      debugPrint('[HttpPredictionRepository] SocketException: $e');
      if (fallbackToFake) {
        debugPrint('[HttpPredictionRepository] Menggunakan fallback lokal.');
        return _fallbackRepo.predict(request);
      }
      return (
        result: null,
        failure: const NetworkFailure('Gagal terhubung ke server backend ML.')
      );
    } catch (e) {
      debugPrint('[HttpPredictionRepository] Error: $e');
      if (fallbackToFake) {
        return _fallbackRepo.predict(request);
      }
      return (result: null, failure: LocalFailure(e.toString()));
    }
  }
}

