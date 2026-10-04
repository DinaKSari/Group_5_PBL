import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B5E3A);
  static const accent = Color(0xFF2E9E5B);
  static const bg = Color(0xFFF4F6F4);
  static const chip = Color(0xFFE3F1E8);
  static const muted = Color(0xFF8A9590);
  static const text = Color(0xFF14231B);
}

/// Satu log prediksi. Fitur ML: umur, suhu, kelembapan, TDS, pH.
class HistoryItem {
  const HistoryItem({
    required this.location,
    required this.inputDate,
    required this.harvestDate,
    required this.daysLeft,
    required this.age,
    required this.temp,
    required this.humidity,
    required this.tds,
    required this.ph,
  });
  final String location, inputDate, harvestDate;
  final int daysLeft, age, humidity, tds;
  final double temp, ph;

  bool get isReady => daysLeft <= 0;
  String get searchText => '$location $inputDate $harvestDate'.toLowerCase();
}

const _dummy = [
  HistoryItem(location: 'Greenhouse Blok A – Rak 1', inputDate: '14 Sep 2026', harvestDate: 'Jumat, 26 Sep 2026', daysLeft: 12, age: 22, temp: 23, humidity: 78, tds: 710, ph: 6.2),
  HistoryItem(location: 'NFT Sayur Sehat – Modul 3', inputDate: '12 Sep 2026', harvestDate: 'Senin, 22 Sep 2026', daysLeft: 8, age: 31, temp: 24.5, humidity: 74, tds: 880, ph: 6.4),
  HistoryItem(location: 'DFT Blok C – Lajur 2', inputDate: '10 Sep 2026', harvestDate: 'Kamis, 7 Okt 2026', daysLeft: 21, age: 15, temp: 22, humidity: 80, tds: 650, ph: 6.0),
  HistoryItem(location: 'Greenhouse Blok B – Rak 4', inputDate: '8 Sep 2026', harvestDate: 'Sabtu, 20 Sep 2026', daysLeft: 0, age: 37, temp: 25, humidity: 72, tds: 800, ph: 6.1),
];

enum _Filter { semua, siap, tumbuh }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _items = _dummy; // TODO: ganti dengan data dari provider/API
  String _query = '';
  _Filter _filter = _Filter.semua;

  List<HistoryItem> get _visible => _items.where((e) {
        final okFilter = switch (_filter) {
          _Filter.semua => true,
          _Filter.siap => e.isReady,
          _Filter.tumbuh => !e.isReady,
        };
        return okFilter && e.searchText.contains(_query);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const HistoryHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                SearchField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase())),
                const SizedBox(height: 10),
                FilterRow(selected: _filter, onSelected: (f) => setState(() => _filter = f)),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Tidak ada riwayat', style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => HistoryTile(list[i]),
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8ECE9))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }
}

class FilterRow extends StatelessWidget {
  const FilterRow({super.key, required this.selected, required this.onSelected});
  final _Filter selected;
  final ValueChanged<_Filter> onSelected;

  static const _labels = {_Filter.semua: 'Semua', _Filter.siap: 'Siap Panen', _Filter.tumbuh: 'Masih Tumbuh'};

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
            side: const BorderSide(color: Color(0xFFE8ECE9)),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile(this.item, {super.key});
  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE8ECE9))),
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
                        Flexible(child: Text('Panen: ${item.harvestDate}', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Input: ${item.inputDate}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
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
                ParamChip(Icons.calendar_month_outlined, '${item.age} hari'),
                ParamChip(Icons.thermostat_outlined, '${item.temp}°C'),
                ParamChip(Icons.cloud_outlined, '${item.humidity}%'),
                ParamChip(Icons.science_outlined, '${item.tds} ppm'),
                ParamChip(Icons.water_drop_outlined, 'pH ${item.ph}'),
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