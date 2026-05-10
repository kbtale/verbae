import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:lingua_verb_master/screens/dashboard_screen.dart';

void main() {
  testWidgets('dashboard screen starts in loading state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DashboardScreen()));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}