import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF1B5E3A);
  static const accent = Color(0xFF2E9E5B);
  static const bg = Color(0xFFF4F6F4);
  static const chip = Color(0xFFE3F1E8);
  static const muted = Color(0xFF8A9590);
  static const text = Color(0xFF14231B);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _params = [
    _Param(Icons.water_drop_outlined, '5.2', 'pH Air', '5.8 – 6.5', 'Optimal'),
    _Param(Icons.science_outlined, '720', 'Nutrisi PPM', '560 – 840', 'AB Mix'),
    _Param(Icons.thermostat_outlined, '23°C', 'Suhu', '20 – 26°C', 'Sejuk'),
    _Param(Icons.cloud_outlined, '78%', 'Kelembaban', '70 – 85%', 'Baik'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Header(),
          Transform.translate(
            offset: const Offset(0, -28),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BatchCard(),
                  SizedBox(height: 14),
                  _PredictionCta(),
                  SizedBox(height: 22),
                  _SectionTitle(),
                  SizedBox(height: 12),
                  _ParamGrid(params: _params),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: _C.chip,
        selectedIndex: 0,
        onDestinationSelected: (_) {}, // TODO: navigasi
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: _C.primary), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Prediksi'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14472C), _C.accent],
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

class _BatchCard extends StatelessWidget {
  const _BatchCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⚡ Batch Terpantau', style: TextStyle(color: _C.muted, fontSize: 13)),
                _Chip('GRAND RAPIDS'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('12', style: TextStyle(color: _C.primary, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
                SizedBox(width: 8),
                Text('Hari Lagi', style: TextStyle(color: _C.accent, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 8),
            Text('Menuju Panen', style: TextStyle(color: _C.text, fontSize: 15, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: _C.muted),
                SizedBox(width: 6),
                Text('Estimasi: Jumat, 26 September 2026', style: TextStyle(color: _C.muted, fontSize: 13)),
              ],
            ),
            SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(value: 22 / 34, minHeight: 7, color: _C.accent, backgroundColor: Color(0xFFE6EAE7)),
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('22 HST (Saat Ini)', style: TextStyle(color: _C.muted, fontSize: 11)),
                Text('Total ~34 HST', style: TextStyle(color: _C.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionCta extends StatelessWidget {
  const _PredictionCta();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDDF0E4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {}, // TODO: navigasi ke prediksi
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.all(Radius.circular(12))),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.monitor_heart_outlined, color: Colors.white),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mulai Prediksi Baru', style: TextStyle(color: _C.text, fontWeight: FontWeight.w700, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Input parameter tinggi, pH, dan PPM selada', style: TextStyle(color: _C.muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _C.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('PARAMETER KRITIS', style: TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        TextButton.icon(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: _C.accent, padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.north_east_rounded, size: 14),
          label: const Text('Lihat Rentang Ideal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _Param {
  const _Param(this.icon, this.value, this.label, this.range, this.tag);
  final IconData icon;
  final String value, label, range, tag;
}

class _ParamGrid extends StatelessWidget {
  const _ParamGrid({required this.params});
  final List<_Param> params;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: params.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 128,
      ),
      itemBuilder: (_, i) => _ParamCard(params[i]),
    );
  }
}

class _ParamCard extends StatelessWidget {
  const _ParamCard(this.p);
  final _Param p;

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
                Icon(p.icon, size: 20, color: _C.accent),
                _Chip(p.tag),
              ],
            ),
            const Spacer(),
            Text(p.value, style: const TextStyle(color: _C.primary, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(p.label, style: const TextStyle(color: _C.muted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(p.range, style: const TextStyle(color: Color(0xFFB0B8B3), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: _C.chip, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: const TextStyle(color: _C.primary, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    );
  }
}