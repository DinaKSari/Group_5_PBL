import '../../domain/entities/prediction_request.dart';

/// Representasi JSON payload ML. Mapping entity → nama kolom backend
/// (umur_hst, suhu, kelembapan, tds, ph) hanya terjadi di sini.
///
/// Identitas (uid/email/nama) TIDAK ikut di body: server membacanya dari klaim
/// ID token yang sudah diverifikasi middleware `firebase.auth`.
class PredictionRequestModel {
  const PredictionRequestModel(this.entity);
  final PredictionRequest entity;

  Map<String, dynamic> toMap() => {
        'umur_hst': entity.plantAge,
        'suhu': entity.temperature,
        'kelembapan': entity.humidity,
        'tds': entity.tds,
        'ph': entity.ph,
        if (entity.location != null && entity.location!.isNotEmpty)
          'lokasi': entity.location,
        if (entity.inputDate != null)
          'tanggal_input': entity.inputDate!.toIso8601String().substring(0, 10),
      };
}
