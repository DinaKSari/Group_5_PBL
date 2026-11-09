import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/notification/data/repositories/notification_repository_impl.dart'
    show firebaseMessagingBackgroundHandler;
import 'features/notification/presentation/providers/notification_providers.dart';
import 'firebase_options.dart';
import 'routes.dart';

final _appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF1B5E3A),
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
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (error, stackTrace) {
    debugPrint('[App] Inisialisasi Firebase gagal: $error\n$stackTrace');
    rethrow;
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
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: _appTheme,
            home: const _StartupPage(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            theme: _appTheme,
            home: _StartupPage(
              errorMessage: 'Firebase gagal dimulai. Periksa konfigurasi dan coba lagi.',
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
          theme: _appTheme,
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
