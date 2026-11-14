import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/session.dart';
import 'core/theme_provider.dart';
import 'features/notification/data/repositories/notification_repository_impl.dart'
    show firebaseMessagingBackgroundHandler;
import 'features/notification/presentation/providers/notification_providers.dart';
import 'firebase_options.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase & background handler top-level sebelum runApp
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      debugPrint('[Firebase] Inisialisasi Firebase warning: $e');
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('[Firebase] Inisialisasi Firebase error: $e');
    }
  }

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[FirebaseMessaging] Background handler error: $e');
  }

  // Pulihkan identitas sesi lama (Firebase persisten) sebelum UI berjalan.
  try {
    final restoredUser = FirebaseAuth.instance.currentUser;
    Session.uid = restoredUser?.uid;
    Session.email = restoredUser?.email;
  } catch (e) {
    debugPrint('[Session] Pulihkan sesi error: $e');
  }

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // Wiring notifikasi setelah router siap; navigasi tetap milik presentation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(notificationRepositoryProvider).initialize(
              onNotificationOpened: (route) => appRouter.go(route),
            );
      } catch (e) {
        debugPrint('[Notification] Inisialisasi gagal: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF1B5E3A),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
        cardColor: Colors.white,
        cardTheme: const CardThemeData(color: Colors.white),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFE3F1E8),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF2E9E5B),
        scaffoldBackgroundColor: const Color(0xFF121814),
        cardColor: const Color(0xFF1D2620),
        cardTheme: const CardThemeData(color: Color(0xFF1D2620)),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF162119),
          indicatorColor: Color(0xFF243B2C),
        ),
      ),
    );
  }
}
