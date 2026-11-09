/// Input ML murni: parameter pertumbuhan & lingkungan tanaman selada.
class PredictionRequest {
  const PredictionRequest({
    required this.plantAge,
    required this.temperature,
    required this.humidity,
    required this.tds,
    required this.ph,
  });

  final double plantAge;
  final double temperature;
  final double humidity;
  final double tds;
  final double ph;
}
