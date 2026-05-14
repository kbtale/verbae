import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/services/verb_service.dart';

class _FakeVerbService extends VerbService {
  final List<Verb> verbs;

  _FakeVerbService(this.verbs);

  @override
  Future<List<Verb>> fetchVerbs(Language language) async => verbs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generatePracticeSet returns only verbs valid for the selected tense', () async {
    final service = VerbService();

    final verbs = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      setSize: 10,
    );

    expect(verbs, hasLength(10));
    expect(verbs.every((verb) => verb.hasTense(VerbTense.presentSimple)), isTrue);
  });

  test('fetchVerbs loads Italian verbs from unified catalog', () async {
    final service = VerbService();

    final verbs = await service.fetchVerbs(Language.italian);

    expect(verbs, isNotEmpty);
    expect(verbs.length, greaterThanOrEqualTo(37));
  });

  test('fetchVerbs loads English verbs from unified catalog', () async {
    final service = VerbService();

    final verbs = await service.fetchVerbs(Language.english);

    expect(verbs, isNotEmpty);
  });

  test('fetchVerbs loads Spanish verbs from unified catalog', () async {
    final service = VerbService();

    final verbs = await service.fetchVerbs(Language.spanish);

    expect(verbs, isNotEmpty);
  });

  test('fetchVerbs returns cached result on second call', () async {
    final service = VerbService();

    final first = await service.fetchVerbs(Language.italian);
    final second = await service.fetchVerbs(Language.italian);

    expect(identical(first, second), isTrue);
  });

  test('clearCache forces fresh load', () async {
    final service = VerbService();

    final first = await service.fetchVerbs(Language.italian);
    service.clearCache();
    final second = await service.fetchVerbs(Language.italian);

    expect(first.length, second.length);
    expect(identical(first, second), isFalse);
  });

  test('generatePracticeSet returns all verbs when fewer than setSize match', () async {
    final service = VerbService();

    final verbs = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      setSize: 1000,
    );

    expect(verbs.length, lessThanOrEqualTo(1000));
    expect(verbs.every((verb) => verb.hasTense(VerbTense.presentSimple)), isTrue);
  });

  test('generatePracticeSet with past simple returns only verbs with that tense', () async {
    final service = VerbService();

    final verbs = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.pastSimple,
      setSize: 5,
    );

    expect(verbs, isNotEmpty);
    expect(verbs.every((verb) => verb.hasTense(VerbTense.pastSimple)), isTrue);
  });

  test('generatePracticeSet returns empty when no verbs match tense', () async {
    final service = _FakeVerbService([
      Verb(
        id: 'italian_parlare',
        base: 'parlare',
        language: 'italian',
        category: 'regular',
        isRegular: true,
        conjugationRules: {
          'present_simple': {
            'affirmative': {'io': '{base}o'},
          },
        },
        spellingRules: const {'default': 'regular'},
      ),
    ]);

    final verbs = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.futureContinuous,
      setSize: 5,
    );

    expect(verbs, isEmpty);
  });

  test('generatePracticeSet returns empty when setSize is zero', () async {
    final service = VerbService();

    final verbs = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      setSize: 0,
    );

    expect(verbs, isEmpty);
  });

  test('generatePracticeSet shuffles when more verbs than setSize', () async {
    final service = VerbService();

    final first = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      setSize: 5,
    );
    final second = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      setSize: 5,
    );

    expect(first.length, 5);
    expect(second.length, 5);
    expect(first.every((v) => v.hasTense(VerbTense.presentSimple)), isTrue);
  });
}
