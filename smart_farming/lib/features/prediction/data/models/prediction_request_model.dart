import '../../domain/entities/prediction_request.dart';

/// Representasi JSON payload ML. Mapping entity → nama kolom Flask
/// (umur_hst, suhu, kelembapan, tds, ph) hanya terjadi di sini.
class PredictionRequestModel {
  const PredictionRequestModel(this.entity);
  final PredictionRequest entity;

  Map<String, double> toMap() => {
        'umur_hst': entity.plantAge,
        'suhu': entity.temperature,
        'kelembapan': entity.humidity,
        'tds': entity.tds,
        'ph': entity.ph,
      };
}
