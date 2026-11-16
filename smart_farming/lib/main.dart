import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/remote_settings.dart';
import 'core/session.dart';
import 'features/history/presentation/providers/history_providers.dart';
import 'features/home/presentation/providers/home_providers.dart';
import 'features/notification/data/repositories/notification_repository_impl.dart'
    show firebaseMessagingBackgroundHandler;
import 'features/notification/presentation/providers/notification_providers.dart';
import 'features/profile/presentation/providers/profile_providers.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[FirebaseMessaging] Background handler error: $e');
  }

  // Remote Config gagal secara tertutup dan tetap memakai nilai build.
  await loadRemoteSettings();

  final restoredUser = FirebaseAuth.instance.currentUser;
  Session.uid = restoredUser?.uid;
  Session.email = restoredUser?.email;
  Session.name = restoredUser?.displayName;
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  late Future<void> _startup;
  bool _notificationsStarted = false;
  StreamSubscription<User?>? _uidChanges;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStartup();
  }

  void _startStartup() {
    _startup = _initializeFirebase();
    _startup.then(
      (_) {
        if (!mounted) return;
        _lastUid = FirebaseAuth.instance.currentUser?.uid;
        _uidChanges?.cancel();
        _uidChanges = FirebaseAuth.instance.authStateChanges().listen((user) {
          Session.uid = user?.uid;
          Session.email = user?.email;
          Session.name = user?.displayName;
          if (user != null) Session.isGuest = false;

          final uid = user?.uid;
          if (uid == _lastUid) return;
          _lastUid = uid;
          ref.invalidate(historyProvider);
          ref.invalidate(monitoringProvider);
          ref.invalidate(currentProfileProvider);
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[Firebase] Bootstrap gagal: $error\n$stackTrace');
      },
    );
  }

  void _retryStartup() {
    setState(() {
      _startStartup();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await ref
          .read(notificationRepositoryProvider)
          .initialize(onNotificationOpened: (route) => appRouter.go(route));
    } catch (error, stackTrace) {
      debugPrint('[App] Inisialisasi notifikasi gagal: $error\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _uidChanges?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hemat kuota ngrok: hanya tarik ulang saat kembali ke foreground, bukan
    // dengan polling. Tamu ditahan karena revalidasi provider untuk sesi tanpa
    // akun hanya membakar request tanpa bisa menampilkan data apa pun.
    if (state == AppLifecycleState.resumed && Session.hasAccount) {
      ref.invalidate(monitoringProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeMode = ThemeMode.system;

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
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
