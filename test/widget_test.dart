import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingua_verb_master/main.dart';

void main() {
  testWidgets('renders the Verbae home screen with all UI elements', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const VerbaeApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Choose a language'), findsOneWidget);
    expect(find.text('Primary action'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
    expect(find.text('Italian'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
  });

  testWidgets('home screen shows tense section and logo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const VerbaeApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Practice tense'), findsOneWidget);
    expect(find.text('View Progress'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
  });
}
