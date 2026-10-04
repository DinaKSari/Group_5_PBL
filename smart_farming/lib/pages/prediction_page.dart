import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B5E3A);
  static const accent = Color(0xFF2E9E5B);
  static const bg = Color(0xFFF4F6F4);
  static const chip = Color(0xFFE3F1E8);
  static const muted = Color(0xFF8A9590);
  static const text = Color(0xFF14231B);
}

/// Definisi satu input ML. Data-driven agar build() pendek & mudah diuji.
class FieldSpec {
  const FieldSpec(this.key, this.icon, this.label, this.unit, this.min, this.max, this.step, this.initial);
  final String key, label, unit;
  final IconData icon;
  final double min, max, step, initial;
  int get decimals => step < 1 ? 1 : 0;
}

const _fields = [
  FieldSpec('umur_hst', Icons.calendar_month_outlined, 'Umur Selada', 'hari', 1, 45, 1, 20),
  FieldSpec('suhu', Icons.thermostat_outlined, 'Suhu', '°C', 10, 40, 0.5, 23),
  FieldSpec('kelembapan', Icons.cloud_outlined, 'Kelembapan', '%', 30, 100, 1, 78),
  FieldSpec('tds', Icons.science_outlined, 'TDS / Nutrisi', 'ppm', 200, 1500, 10, 720),
  FieldSpec('ph', Icons.water_drop_outlined, 'pH Air', '', 4, 9, 0.1, 6.0),
];

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

class PrediksiPage extends StatefulWidget {
  const PrediksiPage({super.key});

  @override
  State<PrediksiPage> createState() => _PrediksiPageState();
}

class _PrediksiPageState extends State<PrediksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _date = ValueNotifier<DateTime>(DateTime.now());

  // ValueNotifier per field: hanya tile yang berubah yang rebuild.
  final _values = {for (final f in _fields) f.key: ValueNotifier<double>(f.initial)};

  @override
  void dispose() {
    _location.dispose();
    _date.dispose();
    for (final v in _values.values) {
      v.dispose();
    }
    super.dispose();
  }

  /// Hanya fitur ML -> dikirim ke Flask.
  Map<String, double> get mlPayload => {for (final e in _values.entries) e.key: e.value.value};

  /// Metadata log -> disimpan untuk riwayat, tidak dikirim ke ML.
  Map<String, String> get meta => {'lokasi': _location.text.trim(), 'tanggal_input': _date.value.toIso8601String()};

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: kirim mlPayload ke Flask, simpan meta bersama hasil, lalu navigasi ke home.
    debugPrint('$meta $mlPayload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const FormHeaderTile(title: 'Form Prediksi Panen', subtitle: 'Input kondisi terkini selada'),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  PlantingInfoTile(location: _location, date: _date),
                  for (final f in _fields) ...[
                    const SizedBox(height: 12),
                    NumberFieldTile(spec: f, value: _values[f.key]!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SubmitBar(onPressed: _submit),
    );
  }
}

class FormHeaderTile extends StatelessWidget {
  const FormHeaderTile({super.key, required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF14472C), AppColors.accent]),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}