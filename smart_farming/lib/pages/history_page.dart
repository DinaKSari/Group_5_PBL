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
