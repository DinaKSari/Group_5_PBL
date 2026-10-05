import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/prediction_page.dart';

abstract final class AppRoute {
  static const home = '/';
  static const prediksi = '/prediksi';
  static const riwayat = '/riwayat';
}

final appRouter = GoRouter(
  initialLocation: AppRoute.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: AppRoute.home, builder: (_, __) => const HomePage())]),
        StatefulShellBranch(routes: [GoRoute(path: AppRoute.prediksi, builder: (_, __) => const PrediksiPage())]),
        StatefulShellBranch(routes: [GoRoute(path: AppRoute.riwayat, builder: (_, __) => const HistoryPage())]),
      ],
    ),
  ],
);

/// Satu-satunya pemilik bottom navigation.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3F1E8),
        selectedIndex: shell.currentIndex,
        // Tap tab aktif -> kembali ke root cabang tersebut.
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Prediksi'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
        ],
      ),
    );
  }
}