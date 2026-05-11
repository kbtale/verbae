import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/screens/practice_screen.dart';
import 'package:lingua_verb_master/models/verb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('practice screen shows loading indicator on start', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticeScreen(
          language: Language.italian,
          tense: VerbTense.futureContinuous,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('practice screen loads verbs and renders practice UI', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticeScreen(
          language: Language.italian,
          tense: VerbTense.presentSimple,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Check Answers'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('practice screen shows empty state when no verbs match tense', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: PracticeScreen(
          language: Language.italian,
          tense: VerbTense.futureContinuous,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No verbs are available'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
