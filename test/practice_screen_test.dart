import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/screens/practice_screen.dart';
import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/services/verb_service.dart';

class _FakeVerbService extends VerbService {
  final List<Verb> verbs;
  _FakeVerbService(this.verbs);

  @override
  Future<List<Verb>> fetchVerbs(Language language) async => verbs;

  @override
  Future<List<Verb>> generatePracticeSet({
    required Language language,
    required VerbTense tense,
    String? category,
    int setSize = 10,
  }) async {
    final filtered = verbs.where((v) => v.hasTense(tense)).toList();
    if (filtered.length > setSize) {
      filtered.shuffle();
      return filtered.take(setSize).toList();
    }
    return filtered;
  }
}

Verb _makeVerb(String base, String language, List<VerbTense> tenses) {
  final rules = <String, dynamic>{};
  for (final t in tenses) {
    final key = t == VerbTense.presentSimple ? 'present_simple'
        : t == VerbTense.pastSimple ? 'past_simple'
        : 'future_simple';
    rules[key] = {
      'affirmative': {'io': '{base}o', 'tu': '{base}i'},
    };
  }
  return Verb(
    id: '${language}_$base',
    base: base,
    language: language,
    category: 'regular',
    isRegular: true,
    conjugationRules: rules,
    spellingRules: const {'default': 'regular'},
  );
}

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
    final fakeService = _FakeVerbService([
      _makeVerb('parlare', 'italian', [VerbTense.presentSimple]),
      _makeVerb('amare', 'italian', [VerbTense.presentSimple]),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(
          language: Language.italian,
          tense: VerbTense.presentSimple,
          verbService: fakeService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Check Answers'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('practice screen shows empty state when no verbs match tense', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fakeService = _FakeVerbService([
      _makeVerb('parlare', 'italian', [VerbTense.presentSimple]),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: PracticeScreen(
          language: Language.italian,
          tense: VerbTense.pastSimple,
          verbService: fakeService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No verbs are available'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
