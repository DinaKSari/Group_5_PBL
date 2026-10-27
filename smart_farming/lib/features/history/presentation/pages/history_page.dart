import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_colors.dart';
import '../../domain/entities/history_entry.dart';
import '../providers/history_providers.dart';

enum HistoryFilter { semua, siap, tumbuh }

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _fmtShort(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String _fmtFull(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_fmtShort(d)}';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _query = '';
  HistoryFilter _filter = HistoryFilter.semua;

  List<HistoryEntry> _visible(List<HistoryEntry> items) {
    final q = _query.trim().toLowerCase();
    return items.where((e) {
      final okFilter = switch (_filter) {
        HistoryFilter.semua => true,
        HistoryFilter.siap => e.isReady,
        HistoryFilter.tumbuh => !e.isReady,
      };
      final okQuery = q.isEmpty ||
          e.location.toLowerCase().contains(q) ||
          _fmtShort(e.inputDate).toLowerCase().contains(q) ||
          _fmtFull(e.harvestDate).toLowerCase().contains(q);
      return okFilter && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const HistoryHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                SearchField(onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 10),
                FilterRow(selected: _filter, onSelected: (f) => setState(() => _filter = f)),
              ],
            ),
          ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Gagal memuat riwayat', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(historyProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                final list = _visible(items);
                if (list.isEmpty) {
                  return const Center(child: Text('Tidak ada riwayat', style: TextStyle(color: AppColors.muted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => HistoryTile(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 20),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF14472C), AppColors.accent])),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Riwayat Prediksi', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 4),
          Text('Rekam jejak estimasi panen selada', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cari lokasi atau tanggal...',
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }
}

class FilterRow extends StatelessWidget {
  const FilterRow({super.key, required this.selected, required this.onSelected});
  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onSelected;

  static const _labels = {HistoryFilter.semua: 'Semua', HistoryFilter.siap: 'Siap Panen', HistoryFilter.tumbuh: 'Masih Tumbuh'};

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final e in _labels.entries) ...[
          ChoiceChip(
            label: Text(e.value),
            selected: selected == e.key,
            onSelected: (_) => onSelected(e.key),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(color: selected == e.key ? Colors.white : AppColors.text, fontSize: 13, fontWeight: FontWeight.w600),
            side: const BorderSide(color: AppColors.border),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile(this.item, {super.key});
  final HistoryEntry item;

  @override
  Widget build(BuildContext context) {
    final p = item.parameters;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: AppColors.primary,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.location, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_available_outlined, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Flexible(child: Text('Panen: ${_fmtFull(item.harvestDate)}', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Input: ${_fmtShort(item.inputDate)}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DaysBadge(item.daysLeft),
            ],
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ParamChip(Icons.calendar_month_outlined, '${p.plantAge.toStringAsFixed(0)} hari'),
                ParamChip(Icons.thermostat_outlined, '${p.temperature}°C'),
                ParamChip(Icons.cloud_outlined, '${p.humidity.toStringAsFixed(0)}%'),
                ParamChip(Icons.science_outlined, '${p.tds.toStringAsFixed(0)} ppm'),
                ParamChip(Icons.water_drop_outlined, 'pH ${p.ph}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DaysBadge extends StatelessWidget {
  const DaysBadge(this.days, {super.key});
  final int days;

  @override
  Widget build(BuildContext context) {
    final ready = days <= 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ready ? const [Color(0xFFE08A1E), Color(0xFFF2B04A)] : const [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 62,
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ready ? '✓' : '$days', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
            Text(ready ? 'PANEN' : 'HARI LAGI', style: const TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class ParamChip extends StatelessWidget {
  const ParamChip(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
