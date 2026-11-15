import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/http_prediction_repository.dart';
import '../../domain/repositories/prediction_repository.dart';

/// Provider utama repositori prediksi: menggunakan HTTP REST API dengan fallback lokal.
final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return const HttpPredictionRepository();
});
