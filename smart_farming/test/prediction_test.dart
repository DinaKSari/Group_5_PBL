import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/core/failures.dart';
import 'package:smart_farming/features/prediction/data/models/prediction_request_model.dart';
import 'package:smart_farming/features/prediction/data/repositories/fake_prediction_repository.dart';
import 'package:smart_farming/features/prediction/domain/entities/prediction_request.dart';

void main() {
  const repo = FakePredictionRepository();

  PredictionRequest validRequest() => const PredictionRequest(
        plantAge: 20,
        temperature: 23,
        humidity: 78,
        tds: 720,
        ph: 6.0,
      );

  group('FakePredictionRepository', () {
    test('parameter valid menghasilkan prediksi hari-menuju-panen yang masuk akal', () async {
      final outcome = await repo.predict(validRequest());
      expect(outcome.failure, isNull);
      expect(outcome.result, isNotNull);
      expect(outcome.result!.daysLeft, inInclusiveRange(0, 60));
      expect(outcome.result!.harvestDate.isAfter(outcome.result!.inputDate), isTrue);
    });

    test('tanaman lebih muda memperpanjang sisa hari menuju panen', () async {
      final muda = await repo.predict(
        PredictionRequest(plantAge: 10, temperature: 23, humidity: 78, tds: 720, ph: 6.0),
      );
      final tua = await repo.predict(
        PredictionRequest(plantAge: 35, temperature: 23, humidity: 78, tds: 720, ph: 6.0),
      );
      expect(muda.result!.daysLeft, greaterThan(tua.result!.daysLeft));
    });

    test('parameter NaN mengembalikan LocalFailure tanpa crash', () async {
      final outcome = await repo.predict(
        const PredictionRequest(
          plantAge: double.nan,
          temperature: 23,
          humidity: 78,
          tds: 720,
          ph: 6.0,
        ),
      );
      expect(outcome.result, isNull);
      expect(outcome.failure, isA<LocalFailure>());
    });
  });

  group('PredictionRequestModel', () {
    test('toMap memakai nama kolom ML contract (umur_hst, suhu, kelembapan, tds, ph)', () {
      final map = PredictionRequestModel(validRequest()).toMap();
      expect(map.keys.toSet(), {'umur_hst', 'suhu', 'kelembapan', 'tds', 'ph'});
      expect(map['umur_hst'], 20);
    });
  });
}
