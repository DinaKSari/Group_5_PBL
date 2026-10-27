import '../../../../core/failures.dart';
import '../../domain/entities/prediction_request.dart';
import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../models/prediction_request_model.dart';

/// Heuristik sementara pengganti model ML sampai Flask API tersedia.
/// Algoritma sebenarnya (regresi dari dataset Lettuce) akan datang dari
/// endpoint /predict; interface domain tidak berubah saat substitusi nanti.
class FakePredictionRepository implements PredictionRepository {
  const FakePredictionRepository();

  static const _idealCycleDays = 38.0;

  @override
  Future<({PredictionResult? result, Failure? failure})> predict(
    PredictionRequest request,
  ) async {
    final payload = PredictionRequestModel(request).toMap();
    if (payload.values.any((v) => v.isNaN || v.isInfinite)) {
      return (result: null, failure: LocalFailure('Parameter tidak valid'));
    }

    await Future.delayed(const Duration(milliseconds: 800));

    // Penyimpangan dari kondisi ideal menunda panen; siklus dasar 38 HST.
    final tempDev = (payload['suhu']! - 23).abs() / 6;
    final humDev = (payload['kelembapan']! - 75).abs() / 15;
    final tdsDev = (payload['tds']! - 700).abs() / 250;
    final phDev = (payload['ph']! - 6.0).abs() / 1.2;
    final penalty = (tempDev + humDev + tdsDev + phDev).clamp(0, 10);

    final daysLeft = (_idealCycleDays - payload['umur_hst']! + penalty).ceil();
    final result = PredictionResult(
      daysLeft: daysLeft.clamp(0, 60),
      inputDate: DateTime.now(),
    );
    return (result: result, failure: null);
  }
}
