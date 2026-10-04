import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B5E3A);
  static const accent = Color(0xFF2E9E5B);
  static const bg = Color(0xFFF4F6F4);
  static const chip = Color(0xFFE3F1E8);
  static const muted = Color(0xFF8A9590);
  static const text = Color(0xFF14231B);
}

class ParamData {
  const ParamData(this.icon, this.value, this.label, this.range, this.tag);
  final IconData icon;
  final String value, label, range, tag;
}

const _params = [
  ParamData(Icons.water_drop_outlined, '5.2', 'pH Air', '5.8 – 6.5', 'Optimal'),
  ParamData(Icons.science_outlined, '720', 'Nutrisi PPM', '560 – 840', 'AB Mix'),
  ParamData(Icons.thermostat_outlined, '23°C', 'Suhu', '20 – 26°C', 'Sejuk'),
  ParamData(Icons.cloud_outlined, '78%', 'Kelembaban', '70 – 85%', 'Baik'),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const HeaderTile(),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const BatchTile(),
                  const SizedBox(height: 14),
                  PredictionTile(onTap: () {}), // TODO: navigasi
                  const SizedBox(height: 22),
                  SectionTile(title: 'PARAMETER KRITIS', action: 'Lihat Rentang Ideal', onAction: () {}),
                  const SizedBox(height: 12),
                  const ParamGrid(params: _params),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const HomeNavTile(),
    );
  }
}

class HeaderTile extends StatelessWidget {
  const HeaderTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14472C), AppColors.accent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HIDROPONIK SELADA', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
                SizedBox(height: 6),
                Text('Halo, Petani Selada 👋', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Pantau pertumbuhan & prediksi waktu panen akurat', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () {},
            style: IconButton.styleFrom(backgroundColor: Colors.white24),
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class BatchTile extends StatelessWidget {
  const BatchTile({
    super.key,
    this.variety = 'GRAND RAPIDS',
    this.daysLeft = 12,
    this.estimate = 'Jumat, 26 September 2026',
    this.currentHst = 22,
    this.totalHst = 34,
  });

  final String variety, estimate;
  final int daysLeft, currentHst, totalHst;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⚡ Batch Terpantau', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ChipTag(variety),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$daysLeft', style: const TextStyle(color: AppColors.primary, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(width: 8),
                const Text('Hari Lagi', style: TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Menuju Panen', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Text('Estimasi: $estimate', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: currentHst / totalHst,
                minHeight: 7,
                color: AppColors.accent,
                backgroundColor: const Color(0xFFE6EAE7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$currentHst HST (Saat Ini)', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                Text('Total ~$totalHst HST', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PredictionTile extends StatelessWidget {
  const PredictionTile({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDDF0E4),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.monitor_heart_outlined, color: Colors.white),
          ),
        ),
        title: const Text('Mulai Prediksi Baru', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: const Text('Input parameter tinggi, pH, dan PPM selada', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text),
      ),
    );
  }
}

class SectionTile extends StatelessWidget {
  const SectionTile({super.key, required this.title, required this.action, required this.onAction});
  final String title, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        TextButton.icon(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.north_east_rounded, size: 14),
          label: Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class ParamGrid extends StatelessWidget {
  const ParamGrid({super.key, required this.params});
  final List<ParamData> params;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: params.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 128,
      ),
      itemBuilder: (_, i) => ParamTile(params[i]),
    );
  }
}

class ParamTile extends StatelessWidget {
  const ParamTile(this.data, {super.key});
  final ParamData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(data.icon, size: 20, color: AppColors.accent),
                ChipTag(data.tag),
              ],
            ),
            const Spacer(),
            Text(data.value, style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(data.label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(data.range, style: const TextStyle(color: Color(0xFFB0B8B3), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class HomeNavTile extends StatelessWidget {
  const HomeNavTile({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.chip,
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Prediksi'),
        NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
      ],
    );
  }
}

class ChipTag extends StatelessWidget {
  const ChipTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    );
  }
}