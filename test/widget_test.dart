import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:lingua_verb_master/main.dart';

void main() {
  testWidgets('renders the Verbae home screen with all UI elements', (tester) async {
    await tester.pumpWidget(const VerbaeApp());

    expect(find.text('Select a Language'), findsOneWidget);
    expect(find.text('View Progress'), findsOneWidget);
    expect(find.text('Italian'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
  });

  testWidgets('home screen shows tense label and logo', (tester) async {
    await tester.pumpWidget(const VerbaeApp());

    expect(find.text('Select Tense'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
