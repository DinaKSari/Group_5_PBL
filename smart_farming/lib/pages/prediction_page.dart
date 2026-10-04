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


/// Form info log (non-ML): lokasi tanam & tanggal input.
class PlantingInfoTile extends StatelessWidget {
  const PlantingInfoTile({super.key, required this.location, required this.date});
  final TextEditingController location;
  final ValueNotifier<DateTime> date;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: date.value,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (d != null) date.value = d;
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8ECE9)));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Info Penanaman', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            const Text('Untuk catatan riwayat', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 14),
            TextFormField(
              controller: location,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Lokasi tanam wajib diisi' : null,
              decoration: InputDecoration(
                labelText: 'Lokasi Tanam',
                hintText: 'cth: Greenhouse Blok A – Rak 1',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.accent),
                isDense: true,
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<DateTime>(
              valueListenable: date,
              builder: (_, d, __) => InkWell(
                onTap: () => _pick(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Input Prediksi',
                    prefixIcon: const Icon(Icons.event_outlined, color: AppColors.accent),
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.muted),
                    isDense: true,
                    border: border,
                    enabledBorder: border,
                  ),
                  child: Text(_fmtDate(d), style: const TextStyle(color: AppColors.text, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberFieldTile extends StatelessWidget {
  const NumberFieldTile({super.key, required this.spec, required this.value});
  final FieldSpec spec;
  final ValueNotifier<double> value;

  void _set(double v) => value.value = v.clamp(spec.min, spec.max).toDouble();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: ValueListenableBuilder<double>(
          valueListenable: value,
          builder: (_, v, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(spec.icon, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(spec.label, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14))),
                  _Stepper(icon: Icons.remove, onTap: v > spec.min ? () => _set(v - spec.step) : null),
                  SizedBox(
                    width: 92,
                    child: Text.rich(
                      TextSpan(
                        text: v.toStringAsFixed(spec.decimals),
                        style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800),
                        children: [TextSpan(text: ' ${spec.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500))],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _Stepper(icon: Icons.add, onTap: v < spec.max ? () => _set(v + spec.step) : null),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 4, activeTrackColor: AppColors.accent, inactiveTrackColor: AppColors.chip, thumbColor: AppColors.primary),
                child: Slider(value: v, min: spec.min, max: spec.max, onChanged: _set),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${spec.min.toStringAsFixed(spec.decimals)} ${spec.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    Text('${spec.max.toStringAsFixed(spec.decimals)} ${spec.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: AppColors.chip, foregroundColor: AppColors.primary),
      icon: Icon(icon, size: 18),
    );
  }
}

class SubmitBar extends StatelessWidget {
  const SubmitBar({super.key, required this.onPressed, this.loading = false});
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE8ECE9)))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: loading
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_graph_rounded),
            label: Text(loading ? 'Memproses...' : 'Prediksi Waktu Panen', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}