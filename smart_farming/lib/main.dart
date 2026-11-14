import 'dart:async';

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

final _lightTheme = ThemeData(
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
);

final _darkTheme = ThemeData(
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
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

Future<void> _initializeFirebase() async {
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

  try {
    final restoredUser = FirebaseAuth.instance.currentUser;
    Session.uid = restoredUser?.uid;
    Session.email = restoredUser?.email;
  } catch (e) {
    debugPrint('[Session] Pulihkan sesi error: $e');
  }
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late Future<void> _startup;
  bool _notificationsStarted = false;

  @override
  void initState() {
    super.initState();
    _startup = _initializeFirebase();
  }

  void _retryStartup() {
    setState(() {
      _startup = _initializeFirebase();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await ref.read(notificationRepositoryProvider).initialize(
            onNotificationOpened: (route) => appRouter.go(route),
          );
    } catch (error, stackTrace) {
      debugPrint('[App] Inisialisasi notifikasi gagal: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            themeMode: themeMode,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            home: const _StartupPage(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            themeMode: themeMode,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            home: _StartupPage(
              errorMessage:
                  'Firebase gagal dimulai. Periksa konfigurasi dan coba lagi.',
              onRetry: _retryStartup,
            ),
          );
        }

        if (!_notificationsStarted) {
          _notificationsStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_initializeNotifications());
          });
        }

        return MaterialApp.router(
          routerConfig: appRouter,
          themeMode: themeMode,
          theme: _lightTheme,
          darkTheme: _darkTheme,
        );
      },
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage({this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasError)
                const CircularProgressIndicator()
              else
                const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Menyiapkan Smart Farming…',
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
