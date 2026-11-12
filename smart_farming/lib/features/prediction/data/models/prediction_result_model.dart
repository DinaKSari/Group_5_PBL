import '../../domain/entities/prediction_result.dart';

/// Representasi response JSON endpoint /predict (baik dari Flask langsung maupun via Laravel).
class PredictionResultModel {
  static PredictionResult fromJson(Map<String, dynamic> json, DateTime inputDate) {
    final days = (json['days_left'] as num?)?.toInt() ?? 0;
    final totalHst = (json['estimated_total_hst'] as num?)?.toInt();

    // Parsing hasil Klasifikasi
    final cls = json['classification'] as Map<String, dynamic>?;
    final stage = cls?['growth_stage']?.toString() ?? 'Vegetatif (Pembesaran)';
    final stageId = (cls?['stage_id'] as num?)?.toInt() ?? 1;

    // Parsing hasil Klusterisasi
    final cluster = json['clustering'] as Map<String, dynamic>?;
    final clusterId = (cluster?['cluster_id'] as num?)?.toInt();
    final profile = cluster?['profile'] as Map<String, dynamic>?;
    final clusterDesc = profile?['description']?.toString() ?? 'Kondisi Pertumbuhan Normal';

    return PredictionResult(
      daysLeft: days,
      inputDate: inputDate,
      growthStage: stage,
      stageId: stageId,
      clusterDesc: clusterDesc,
      clusterId: clusterId,
      estimatedTotalHst: totalHst,
    );
  }
}
