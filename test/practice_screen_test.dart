import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:lingua_verb_master/screens/practice_screen.dart';
import 'package:lingua_verb_master/models/verb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('practice screen shows loading indicator on start', (tester) async {
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
}
