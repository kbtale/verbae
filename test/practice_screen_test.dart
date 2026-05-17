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
    final categorized = category != null
        ? filtered.where((v) => v.category == category).toList()
        : filtered;
    if (categorized.length > setSize) {
      categorized.shuffle();
      return categorized.take(setSize).toList();
    }
    return categorized;
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

  testWidgets('category dropdown persists selection and filters verbs', (tester) async {
    SharedPreferences.setMockInitialValues({'practice_category': 'Irregular'});

    final irregular = Verb(
      id: 'italian_irreg',
      base: 'irreg',
      language: 'italian',
      category: 'irregular',
      isRegular: false,
      conjugationRules: {
        'present_simple': {
          'affirmative': {'io': 'irrego', 'tu': 'irregi'}
        }
      },
      spellingRules: const {'default': 'irregular'},
    );

    final fakeService = _FakeVerbService([
      _makeVerb('parlare', 'italian', [VerbTense.presentSimple]),
      irregular,
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

    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(find.text('irreg'), findsOneWidget);
    expect(find.text('parlare'), findsNothing);
  });
}
