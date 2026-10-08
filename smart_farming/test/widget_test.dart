import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_farming/main.dart';

void main() {
  testWidgets('App renders home page with greeting', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the home page greeting is displayed.
    expect(find.text('Halo, Petani Selada 👋'), findsOneWidget);
  });

  testWidgets('App shows bottom navigation bar with 3 destinations', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify NavigationBar is present.
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify all 3 destination labels exist.
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Prediksi'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
