import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../prediction/domain/entities/parameter_spec.dart';
import '../../domain/entities/sensor_entry.dart';
import '../providers/sensor_providers.dart';

/// Halaman "Catat Parameter Kebun" (keputusan P4).
///
/// Project ini belum punya perangkat sensor, jadi dashboard hanya bisa berisi
/// angka yang kalian catat sendiri. Form ini dibangun dari [kGrowthParameters]
/// supaya rentang yang diterima di sini IDENTIK dengan validasi
/// `SensorController::store()` — tidak ada angka yang ditulis dua kali.
class SensorEntryPage extends ConsumerStatefulWidget {
  const SensorEntryPage({super.key});

  @override
  ConsumerState<SensorEntryPage> createState() => _SensorEntryPageState();
}

class _SensorEntryPageState extends ConsumerState<SensorEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _values = {
    for (final spec in kGrowthParameters)
      spec.key: TextEditingController(text: _defaultText(spec)),
  };

  bool _saving = false;

  @override
  void dispose() {
    _location.dispose();
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _defaultText(ParameterSpec spec) => spec.decimals == 0
      ? spec.defaultValue.toStringAsFixed(0)
      : spec.defaultValue.toStringAsFixed(1);

  /// Koma desimal diterima karena keyboard/kebiasaan lokal; server tetap
  /// menerima angka titik karena dikirim apa adanya lewat JSON.
  static double? _parse(ParameterSpec spec, String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || !spec.isAcceptable(value)) return null;
    return value;
  }

  SensorEntry get _entry => SensorEntry({
    for (final spec in kGrowthParameters)
      spec.key: _parse(spec, _values[spec.key]!.text) ?? spec.defaultValue,
  }, lokasi: _location.text.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final failure = await ref.read(sensorRepositoryProvider).record(_entry);
    if (!mounted) return;
    setState(() => _saving = false);

    final messenger = ScaffoldMessenger.of(context);
    if (failure != null) {
      final isAuth = failure is AuthFailure;
      messenger.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: isAuth
              ? SnackBarAction(
                  label: 'Masuk',
                  onPressed: () => context.go(AppRoute.login),
                )
              : null,
        ),
      );
      return;
    }

    // Dashboard langsung menunjukkan angka baru tanpa menunggu pull-to-refresh.
    ref.invalidate(monitoringProvider);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Parameter tersimpan. Dashboard sudah diperbarui.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        title: const Text('Catat Parameter Kebun'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text(
              'Ukur lalu tulis kondisi kebun kalian sekarang. Data ini yang '
              'menampilkan angka di dashboard — belum ada sensor otomatis.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final spec in kGrowthParameters) ...[
                    _ParameterField(spec: spec, controller: _values[spec.key]!),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _location,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi (opsional)',
                      hintText: 'Bedeng 3 / Rooftop',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Catatan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParameterField extends StatelessWidget {
  const _ParameterField({required this.spec, required this.controller});

  final ParameterSpec spec;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: spec.unit.isEmpty
            ? spec.label
            : '${spec.label} (${spec.unit})',
        hintText:
            '${spec.min.toStringAsFixed(spec.decimals)} – '
            '${spec.max.toStringAsFixed(spec.decimals)}',
        helperText:
            'Wajar: ${spec.min.toStringAsFixed(spec.decimals)} – '
            '${spec.max.toStringAsFixed(spec.decimals)}${spec.unit.isEmpty ? '' : ' ${spec.unit}'}',
      ),
      validator: (text) {
        if (text == null || text.trim().isEmpty) {
          return '${spec.label} wajib diisi';
        }
        if (_SensorEntryPageState._parse(spec, text) == null) {
          return '${spec.label} harus di antara ${spec.min.toStringAsFixed(spec.decimals)} '
              'dan ${spec.max.toStringAsFixed(spec.decimals)}';
        }
        return null;
      },
    );
  }
}
