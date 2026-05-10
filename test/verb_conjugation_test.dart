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
}