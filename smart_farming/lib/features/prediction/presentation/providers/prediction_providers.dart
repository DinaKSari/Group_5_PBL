import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_prediction_repository.dart';
import '../../domain/repositories/prediction_repository.dart';

/// TODO(Flask): ganti FakePredictionRepository dengan HttpPredictionRepository
/// begitu endpoint /predict tersedia. Tidak ada file lain yang perlu berubah.
final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return const FakePredictionRepository();
});
