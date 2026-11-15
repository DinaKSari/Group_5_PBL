import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/session.dart';
import 'features/home/presentation/providers/home_providers.dart';
import 'features/notification/data/repositories/notification_repository_impl.dart'
    show firebaseMessagingBackgroundHandler;
import 'features/notification/presentation/providers/notification_providers.dart';
import 'firebase_options.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase & background handler top-level sebelum runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Sumber kebenaran sesi: kejadian pertama = pemulihan user yang tersimpan
  // Firebase, selanjutnya login/logout. Router & layer data hanya membaca
  // Session, tidak pernah menebak identitas sendiri.
  FirebaseAuth.instance.authStateChanges().listen((user) {
    Session.uid = user?.uid;
    Session.email = user?.email;
    Session.name = user?.displayName;
    if (user != null) Session.isGuest = false;
    authStateNotifier.value = authStateNotifier.value + 1;
  });

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Wiring notifikasi setelah router siap; navigasi tetap milik presentation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationRepositoryProvider).initialize(
            onNotificationOpened: (route) => appRouter.go(route),
          );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hemat kuota ngrok: hanya tarik ulang saat kembali ke foreground, bukan
    // dengan polling.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(monitoringProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E3A),
      ),
    );
  }
}
