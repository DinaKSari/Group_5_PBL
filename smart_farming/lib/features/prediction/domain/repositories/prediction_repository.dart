import '../../../../core/failures.dart';
import '../entities/prediction_request.dart';
import '../entities/prediction_result.dart';

/// Kontrak layanan prediksi. Implementasi: Flask HTTP (nanti) atau heuristic fake.
abstract class PredictionRepository {
  Future<({PredictionResult? result, Failure? failure})> predict(PredictionRequest request);
}
