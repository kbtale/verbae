import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/services/verb_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = VerbService();

  for (final language in Language.values) {
    group(language.name, () {
      test('loads at least one verb', () async {
        final verbs = await service.fetchVerbs(language);
        expect(verbs, isNotEmpty);
      });

      test('every verb has at least one tense or irregular form', () async {
        final verbs = await service.fetchVerbs(language);
        for (final verb in verbs) {
          final hasTenses = verb.tenses.isNotEmpty;
          final hasForms = verb.irregularForms != null && verb.irregularForms!.isNotEmpty;
          expect(hasTenses || hasForms, isTrue,
            reason: 'Verb ${verb.base} has no tenses or forms',
          );
        }
      });

      test('every verb has a non-empty base', () async {
        final verbs = await service.fetchVerbs(language);
        for (final verb in verbs) {
          expect(verb.base, isNotEmpty);
          expect(verb.base.trim(), verb.base);
        }
      });
    });
  }

  test('Italian has 10 verbs for present, past, and future simple', () async {
    final present = await service.generatePracticeSet(
      language: Language.italian, tense: VerbTense.presentSimple, setSize: 10,
    );
    final past = await service.generatePracticeSet(
      language: Language.italian, tense: VerbTense.pastSimple, setSize: 10,
    );
    final future = await service.generatePracticeSet(
      language: Language.italian, tense: VerbTense.futureSimple, setSize: 10,
    );

    expect(present.length, 10);
    expect(past.length, 10);
    expect(future.length, 10);
  });

  test('English loads practice sets for each tense', () async {
    final present = await service.generatePracticeSet(
      language: Language.english, tense: VerbTense.presentSimple, setSize: 5,
    );
    final past = await service.generatePracticeSet(
      language: Language.english, tense: VerbTense.pastSimple, setSize: 5,
    );
    final future = await service.generatePracticeSet(
      language: Language.english, tense: VerbTense.futureSimple, setSize: 5,
    );

    expect(present.isNotEmpty, isTrue);
    expect(past.isNotEmpty, isTrue);
    expect(future.isNotEmpty, isTrue);
    expect(present.every((v) => v.hasTense(VerbTense.presentSimple)), isTrue);
    expect(past.every((v) => v.hasTense(VerbTense.pastSimple)), isTrue);
    expect(future.every((v) => v.hasTense(VerbTense.futureSimple)), isTrue);
  });

  test('Spanish loads practice sets for each tense', () async {
    final present = await service.generatePracticeSet(
      language: Language.spanish, tense: VerbTense.presentSimple, setSize: 5,
    );
    final past = await service.generatePracticeSet(
      language: Language.spanish, tense: VerbTense.pastSimple, setSize: 5,
    );
    final future = await service.generatePracticeSet(
      language: Language.spanish, tense: VerbTense.futureSimple, setSize: 5,
    );

    final all = [...present, ...past, ...future];
    expect(all.isNotEmpty, isTrue);
    expect(all.every((v) => v.hasTense(VerbTense.presentSimple) ||
                            v.hasTense(VerbTense.pastSimple) ||
                            v.hasTense(VerbTense.futureSimple),), isTrue);
  });

  test('each verb in Italian practice set can conjugate for each subject', () async {
    final set = await service.generatePracticeSet(
      language: Language.italian, tense: VerbTense.presentSimple, setSize: 5,
    );

    for (final verb in set) {
      final conjugations = verb.tenses[VerbTense.presentSimple] ?? {};
      for (final subject in conjugations.keys) {
        final conjugated = verb.conjugate(
          tense: VerbTense.presentSimple,
          subject: subject,
          form: VerbForm.affirmative,
        );
        expect(conjugated, isNotEmpty,
          reason: '${verb.base} conjugate presentSimple $subject returned empty',
        );
      }
    }
  });

  test('Italian requires exactly 68 verbs in the catalog', () async {
    final verbs = await service.fetchVerbs(Language.italian);
    expect(verbs.length, 68);
  });
}
