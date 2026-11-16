import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/onboarding/presentation/pages/splash_page.dart';
import 'features/prediction/presentation/pages/prediction_page.dart';
import 'features/sensor/presentation/pages/sensor_entry_page.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const dashboard = '/dashboard';
  static const prediksi = '/prediksi';
  static const riwayat = '/riwayat';
  static const profile = '/profile';

  /// Entri manual parameter kebun (keputusan P4). Route push, bukan tab:
  /// dipakai sesekali setelah mengukur, bukan tempat yang dituju tiap sesi.
  static const sensor = '/sensor-entry';

  /// Rute default yang dituju saat notifikasi tidak menyertakan rute spesifik
  static const defaultRoute = riwayat;
}

/// Alias backward-compatibility untuk AppRoutes
typedef AppRoute = AppRoutes;

/// Naik setiap kali status login berubah (didengarkan di main.dart dari
/// FirebaseAuth.authStateChanges) sehingga guard router ikut ter-evaluasi lagi.
final authStateNotifier = ValueNotifier<int>(0);

/// Halaman yang memerlukan identitas; hanya boleh dibuka lewat splash/login
/// supaya token Mode Tamu tidak pernah dipakai ke API.
final _privateLocations = {
  AppRoutes.home,
  AppRoutes.prediksi,
  AppRoutes.riwayat,
  AppRoutes.sensor,
};

/// Mode Tamu boleh melihat tiga tab (read-only, ditolak di layer data), tapi
/// tidak boleh mencatat parameter kebun: tanpa akun tidak ada pemilik baris.
const _guestLocations = {AppRoutes.home, AppRoutes.prediksi, AppRoutes.riwayat};

/// Murni supaya bisa diuji tanpa widget/Firebase.
String? redirectLocationFor(String location) {
  if (!_privateLocations.contains(location)) return null;
  if (Session.hasAccount) return null;
  if (Session.isGuest && _guestLocations.contains(location)) return null;
  return AppRoutes.splash;
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: Listenable.merge([authStateNotifier, sessionExpiredNotifier]),
  redirect: (context, state) => redirectLocationFor(state.matchedLocation),
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => AppRoutes.splash,
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),
    // Di luar StatefulShellRoute: bottom navigation tetap 3 tab seperti
    // sekarang, halaman ini ditumpuk di atas Home saat dipakai.
    GoRoute(
      path: AppRoutes.sensor,
      builder: (context, state) => const SensorEntryPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      redirect: (context, state) => AppRoutes.home,
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.prediksi,
              builder: (context, state) => const PrediksiPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.riwayat,
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: isDark ? const Color(0xFF162119) : Colors.white,
        indicatorColor: isDark ? const Color(0xFF243B2C) : const Color(0xFFE3F1E8),
        selectedIndex: shell.currentIndex,
        // Tap tab aktif -> kembali ke root cabang tersebut.
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Prediksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}