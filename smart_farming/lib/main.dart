import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router( // wajib .router, bukan MaterialApp biasa
      routerConfig: appRouter,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1B5E3A)),
    );
  }
}