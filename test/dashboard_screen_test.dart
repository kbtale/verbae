import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/screens/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard screen starts in loading state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('dashboard shows first-run empty state when there is no activity', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No practice data yet'), findsOneWidget);
    expect(find.textContaining('Complete your first practice session'), findsOneWidget);
  });
}