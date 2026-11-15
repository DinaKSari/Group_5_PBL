import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api_client.dart';
import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../domain/entities/prediction_request.dart';
import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../models/prediction_request_model.dart';
import '../models/prediction_result_model.dart';

/// Repository prediksi riil melalui REST API Laravel.
///
/// Tidak ada fallback ke data palsu: kegagalan backend harus terlihat oleh
/// pengguna, supaya angka yang muncul di layar selalu hasil model ML sungguhan.
class HttpPredictionRepository implements PredictionRepository {
  HttpPredictionRepository({http.Client? client})
      : _api = ApiClient(client: client);

  final ApiClient _api;

  static const _timeout = Duration(seconds: 15);

  @override
  Future<({PredictionResult? result, Failure? failure})> predict(
    PredictionRequest request,
  ) async {
    // Mode Tamu read-only: tidak ada identitas untuk menyimpan riwayat, jadi
    // jangan berpura-pura mengirim.
    if (Session.isGuest) {
      return (
        result: null,
        failure: const AuthFailure(
          'Masuk untuk menyimpan prediksi ke akun kalian.',
        ),
      );
    }

    final http.Response response;
    try {
      response = await _api.postJson(
        '/predict',
        PredictionRequestModel(request).toMap(),
        timeout: _timeout,
      );
    } on SocketException catch (e) {
      debugPrint('[HttpPredictionRepository] SocketException: $e');
      return (
        result: null,
        failure: const NetworkFailure(
          'Backend tidak terjangkau. Pastikan Laravel (8000) dan Flask ML (5000) berjalan.',
        ),
      );
    } on TimeoutException {
      return (
        result: null,
        failure: ServerFailure(
          'Layanan prediksi ML tidak dapat dihubungi (melebihi ${_timeout.inSeconds} detik).',
        ),
      );
    } catch (e) {
      debugPrint('[HttpPredictionRepository] Error: $e');
      return (result: null, failure: LocalFailure(e.toString()));
    }

    // Laravel membalas 201 (store sukses); Flask lama membalas 200.
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = ApiClient.jsonBody(response);
      if (data == null) {
        return (
          result: null,
          failure: ServerFailure('Respons server tidak dapat dibaca.'),
        );
      }
      try {
        return (
          result: PredictionResultModel.fromJson(data, DateTime.now()),
          failure: null,
        );
      } catch (e) {
        debugPrint('[HttpPredictionRepository] Parse gagal: $e');
        return (
          result: null,
          failure: ServerFailure('Format hasil prediksi tidak dikenali.'),
        );
      }
    }

    if (response.statusCode == 401) {
      return (
        result: null,
        failure: const AuthFailure(
          'Sesi kalian sudah kedaluwarsa. Masuk kembali untuk menyimpan prediksi.',
        ),
      );
    }

    return (result: null, failure: ServerFailure(_errorMessage(response)));
  }

  /// Laravel mengirim penyebab kegagalan pada `errors` (422) atau `message` (5xx).
  /// Membuang keduanya membuat error di perangkat tidak bisa ditindaklanjuti.
  String _errorMessage(http.Response response) {
    final data = ApiClient.jsonBody(response);
    if (data != null) {
      final errors = data['errors'];
      if (errors is Map) {
        final flat = errors.values
            .expand((e) => e is List ? e.map((x) => '$x') : ['$e'])
            .join(', ');
        if (flat.isNotEmpty) return flat;
      }
      if (errors is List && errors.isNotEmpty) return errors.join(', ');

      final message = data['message'];
      if (message is String && message.isNotEmpty && message != 'Server Error') {
        return message;
      }
    }
    return 'Server mengembalikan status: ${response.statusCode}';
  }
}
