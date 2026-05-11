import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:lingua_verb_master/screens/practice_screen.dart';
import 'package:lingua_verb_master/models/verb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('practice screen shows loading indicator on start', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.futureContinuous,
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('practice screen loads verbs and renders practice UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.presentSimple,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Check Answers'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('practice screen shows empty state when no verbs match tense', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.futureContinuous,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('No verbs are available'), findsOneWidget);
  });

  testWidgets('Check Answers button is present', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.presentSimple,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Check Answers'), findsOneWidget);
  });

  testWidgets('Next Verb button is present in non-master mode', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.presentSimple,
      ),
    ));
    await tester.pumpAndSettle();

    final nextButton = find.text('Next Verb');
    expect(nextButton, findsOneWidget);
  });

  testWidgets('Master Mode switch is present', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.presentSimple,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Master Mode'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('practice screen shows infinitive of current verb', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.presentSimple,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Infinitive:'), findsOneWidget);
  });

  testWidgets('practice complete dialog appears after advancing through all verbs', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticeScreen(
        language: Language.italian,
        tense: VerbTense.presentSimple,
      ),
    ));
    await tester.pumpAndSettle();

    int maxIterations = 20;
    while (maxIterations > 0) {
      maxIterations--;

      if (find.text('Practice Complete!').evaluate().isNotEmpty) {
        break;
      }

      final checkButton = find.text('Check Answers');
      if (checkButton.evaluate().isNotEmpty && tester.widget<ElevatedButton>(checkButton).onPressed != null) {
        await tester.tap(checkButton);
        await tester.pumpAndSettle();
      }

      final nextButton = find.text('Next Verb');
      if (nextButton.evaluate().isNotEmpty && tester.widget<ElevatedButton>(nextButton).onPressed != null) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Practice Complete!'), findsOneWidget);
  });
}
