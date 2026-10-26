import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD
import 'pages/main_shell_page.dart';
=======
>>>>>>> 98d1319d8447f7ac23f3a3a904ab2ad51894b1f7

import 'routes.dart';
import 'services/device_api.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase & background handler top-level sebelum runApp
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) => MaterialApp(
        title: 'Smart Farming - Hidroponik Selada',
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const MainShellPage(),
=======
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    // Inisialisasi push service dan penanganan terminated state setelah router siap
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushService.instance.initialize(
        onToken: (token) {
          DeviceApi.registerDevice(token);
        },
>>>>>>> 98d1319d8447f7ac23f3a3a904ab2ad51894b1f7
      );
      await PushService.instance.setupTerminatedMessage();
    });
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