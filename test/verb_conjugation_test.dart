import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/models/verb.dart';

void main() {
  test('conjugates an Italian regular verb using template rules', () {
    final verb = Verb(
      id: 'italian_parlare',
      base: 'parlare',
      language: 'italian',
      category: 'regular',
      isRegular: true,
      conjugationRules: {
        'present_simple': {
          'affirmative': {
            'io': '{base}o',
            'tu': '{base}i',
            'luiLei': '{base}a',
            'noi': '{base}iamo',
            'voi': '{base}ate',
            'loro': '{base}ano',
          },
        },
        'past_simple': {
          'affirmative': {
            'io': '{base}ai',
            'tu': '{base}asti',
            'luiLei': '{base}ò',
            'noi': '{base}ammo',
            'voi': '{base}aste',
            'loro': '{base}arono',
          },
        },
        'future_simple': {
          'affirmative': {
            'io': '{base}erò',
            'tu': '{base}erai',
            'luiLei': '{base}erà',
            'noi': '{base}eremo',
            'voi': '{base}erete',
            'loro': '{base}eranno',
          },
        },
      },
      spellingRules: const {'default': 'regular'},
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'io',
        form: VerbForm.affirmative,
      ),
      'parlo',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.pastSimple,
        subject: 'tu',
        form: VerbForm.affirmative,
      ),
      'parlasti',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.futureSimple,
        subject: 'noi',
        form: VerbForm.affirmative,
      ),
      'parleremo',
    );
  });

  test('conjugates an Italian irregular verb from explicit forms', () {
    final verb = Verb(
      id: 'italian_essere',
      base: 'essere',
      language: 'italian',
      category: 'irregular',
      isRegular: false,
      conjugationRules: const {},
      spellingRules: const {},
      irregularForms: {
        'present_simple': {
          'affirmative': {
            'io': 'sono',
            'tu': 'sei',
            'luiLei': 'è',
            'noi': 'siamo',
            'voi': 'siete',
            'loro': 'sono',
          },
        },
        'past_simple': {
          'affirmative': {
            'io': 'ero',
            'tu': 'eri',
            'luiLei': 'era',
            'noi': 'eravamo',
            'voi': 'eravate',
            'loro': 'erano',
          },
        },
        'future_simple': {
          'affirmative': {
            'io': 'sarò',
            'tu': 'sarai',
            'luiLei': 'sarà',
            'noi': 'saremo',
            'voi': 'sarete',
            'loro': 'saranno',
          },
        },
      },
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'io',
        form: VerbForm.affirmative,
      ),
      'sono',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.pastSimple,
        subject: 'noi',
        form: VerbForm.affirmative,
      ),
      'eravamo',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.futureSimple,
        subject: 'loro',
        form: VerbForm.affirmative,
      ),
      'saranno',
    );
  });

  test('conjugates an English regular verb in present simple', () {
    final verb = Verb(
      id: 'english_walk',
      base: 'walk',
      language: 'english',
      category: 'regular',
      isRegular: true,
      conjugationRules: {
        'present_simple': {
          'affirmative': {
            'I': '{base}',
            'you': '{base}',
            'we': '{base}',
            'they': '{base}',
          },
        },
      },
      spellingRules: const {},
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'I',
        form: VerbForm.affirmative,
      ),
      'walk',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'you',
        form: VerbForm.affirmative,
      ),
      'walk',
    );
  });

  test('conjugates an English regular verb in past simple using template', () {
    final verb = Verb(
      id: 'english_play',
      base: 'play',
      language: 'english',
      category: 'regular',
      isRegular: true,
      conjugationRules: {
        'past_simple': {
          'affirmative': {
            'I': 'played',
          },
        },
      },
      spellingRules: const {},
    );

    expect(
      verb.conjugate(
        tense: VerbTense.pastSimple,
        subject: 'I',
        form: VerbForm.affirmative,
      ),
      'played',
    );
  });

  test('conjugates an English irregular verb "be"', () {
    final verb = Verb(
      id: 'english_be',
      base: 'be',
      language: 'english',
      category: 'irregular',
      isRegular: false,
      conjugationRules: const {},
      spellingRules: const {},
      irregularForms: {
        'present_simple': {
          'affirmative': {
            'I': 'am',
            'you': 'are',
            'he/she/it': 'is',
            'we': 'are',
            'they': 'are',
          },
        },
        'past_simple': {
          'affirmative': {
            'I': 'was',
            'you': 'were',
            'he/she/it': 'was',
            'we': 'were',
            'they': 'were',
          },
        },
      },
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'I',
        form: VerbForm.affirmative,
      ),
      'am',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'he/she/it',
        form: VerbForm.affirmative,
      ),
      'is',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.pastSimple,
        subject: 'we',
        form: VerbForm.affirmative,
      ),
      'were',
    );
  });

  test('conjugates a Spanish regular verb across tenses', () {
    final verb = Verb(
      id: 'spanish_hablar',
      base: 'hablar',
      language: 'spanish',
      category: 'regular',
      isRegular: true,
      conjugationRules: {
        'present_simple': {
          'affirmative': {
            'yo': '{base}o',
            'tu': '{base}as',
            'elEllaUsted': '{base}a',
            'nosotros': '{base}amos',
          },
        },
        'past_simple': {
          'affirmative': {
            'yo': '{base}é',
          },
        },
      },
      spellingRules: const {'default': 'regular'},
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'yo',
        form: VerbForm.affirmative,
      ),
      'hablo',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'tu',
        form: VerbForm.affirmative,
      ),
      'hablas',
    );
    expect(
      verb.conjugate(
        tense: VerbTense.pastSimple,
        subject: 'yo',
        form: VerbForm.affirmative,
      ),
      'hablé',
    );
  });

  test('returns empty string for missing tense', () {
    final verb = Verb(
      id: 'test_missing',
      base: 'test',
      language: 'english',
      category: 'regular',
      isRegular: true,
      conjugationRules: const {},
      spellingRules: const {},
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'I',
        form: VerbForm.affirmative,
      ),
      '',
    );
  });

  test('returns empty string for missing subject in template', () {
    final verb = Verb(
      id: 'test_partial',
      base: 'test',
      language: 'english',
      category: 'regular',
      isRegular: true,
      conjugationRules: {
        'present_simple': {
          'affirmative': {
            'I': '{base}',
          },
        },
      },
      spellingRules: const {},
    );

    expect(
      verb.conjugate(
        tense: VerbTense.presentSimple,
        subject: 'you',
        form: VerbForm.affirmative,
      ),
      '',
    );
  });
}
