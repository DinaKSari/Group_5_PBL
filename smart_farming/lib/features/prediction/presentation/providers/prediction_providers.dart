import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/http_prediction_repository.dart';
import '../../domain/repositories/prediction_repository.dart';

/// Provider utama repositori prediksi: HTTP REST API Laravel, tanpa data palsu.
final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return HttpPredictionRepository();
});
