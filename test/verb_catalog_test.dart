import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/models/verb_catalog.dart';

void main() {
  test('parses a language catalog with regular and irregular verbs', () {
    final catalogJson = <String, dynamic>{
      'language': 'english',
      'regular': 'assets/verbs/english_regular.json',
      'irregular': 'assets/verbs/english_irregular.json',
    };

    final catalog = VerbCatalog.fromJson(catalogJson);

    expect(catalog.language, Language.english);
    expect(catalog.regularFile, 'assets/verbs/english_regular.json');
    expect(catalog.irregularFile, 'assets/verbs/english_irregular.json');
    expect(catalog.verbs, isEmpty);
  });

  test('parses a unified language catalog with verb entries', () {
    final catalogJson = <String, dynamic>{
      'language': 'english',
      'verbs': [
        {
          'type': 'regular',
          'base': 'walk',
          'language': 'english',
          'category': 'regular',
          'conjugation_rules': {
            'present_simple': {
              'affirmative': {
                'I': '{base}',
              },
            },
          },
          'spelling_rules': {
            'third_person_singular': 'default',
          },
        },
        {
          'type': 'irregular',
          'base': 'be',
          'language': 'english',
          'category': 'irregular',
          'forms': {
            'present_simple': {
              'affirmative': {
                'I': 'am',
              },
            },
          },
        },
      ],
    };

    final catalog = VerbCatalog.fromJson(catalogJson);

    expect(catalog.language, Language.english);
    expect(catalog.verbs, hasLength(2));
    expect(catalog.verbs.first.isRegular, isTrue);
    expect(catalog.verbs.last.isRegular, isFalse);
  });

  test('unified italian catalog loads verbs', () {
    final italianJson = jsonDecode(File('assets/verbs/italian.json').readAsStringSync()) as Map<String, dynamic>;
    final catalog = VerbCatalog.fromJson(italianJson);

    expect(catalog.language, Language.italian);
    expect(catalog.verbs, hasLength(59));
    expect(catalog.verbs.any((verb) => verb.base == 'parlare' && verb.isRegular), isTrue);
    expect(catalog.verbs.any((verb) => verb.base == 'essere' && !verb.isRegular), isTrue);
  });

  test('rejects malformed unified verb entries', () {
    final catalogJson = <String, dynamic>{
      'language': 'english',
      'verbs': [
        {
          'type': 'regular',
          'base': '',
          'language': 'english',
          'category': 'regular',
          'conjugation_rules': {},
          'spelling_rules': {},
        },
      ],
    };

    expect(() => VerbCatalog.fromJson(catalogJson), throwsFormatException);
  });

  test('rejects unified verbs whose language does not match the catalog', () {
    final catalogJson = <String, dynamic>{
      'language': 'italian',
      'verbs': [
        {
          'type': 'regular',
          'base': 'walkare',
          'language': 'english',
          'category': 'regular',
          'conjugation_rules': {},
          'spelling_rules': {},
        },
      ],
    };

    expect(() => VerbCatalog.fromJson(catalogJson), throwsFormatException);
  });

  test('rejects catalog with empty verb array', () {
    final catalogJson = <String, dynamic>{
      'language': 'english',
      'verbs': <dynamic>[],
    };

    expect(() => VerbCatalog.fromJson(catalogJson), throwsFormatException);
  });

  test('rejects catalog without language field', () {
    final catalogJson = <String, dynamic>{
      'verbs': <dynamic>[],
    };

    expect(() => VerbCatalog.fromJson(catalogJson), throwsFormatException);
  });

  test('parses catalog with only irregular verbs', () {
    final catalogJson = <String, dynamic>{
      'language': 'english',
      'verbs': [
        {
          'type': 'irregular',
          'base': 'go',
          'language': 'english',
          'category': 'irregular',
          'forms': {
            'present_simple': {
              'affirmative': {
                'I': 'go',
              },
            },
          },
        },
      ],
    };

    final catalog = VerbCatalog.fromJson(catalogJson);

    expect(catalog.language, Language.english);
    expect(catalog.verbs, hasLength(1));
    expect(catalog.verbs.first.isRegular, isFalse);
    expect(catalog.verbs.first.base, 'go');
  });
}