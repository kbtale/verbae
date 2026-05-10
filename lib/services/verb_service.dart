import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/verb_catalog.dart';
import '../models/verb.dart';

class VerbService {
  final Map<Language, String> _verbFiles = const {
    Language.english: 'assets/verbs/english.json',
    Language.spanish: 'assets/verbs/spanish.json',
    Language.italian: 'assets/verbs/italian.json',
  };

  final Map<Language, List<Verb>> _verbCache = {};

  Future<List<Verb>> fetchVerbs(Language language) async {
    if (_verbCache.containsKey(language)) {
      return _verbCache[language]!;
    }

    final catalog = await _loadCatalog(language);
    if (catalog.verbs.isNotEmpty) {
      _verbCache[language] = catalog.verbs;
      return catalog.verbs;
    }

    final regularVerbs = await _loadVerbList(catalog.regularFile, language, true);
    final irregularVerbs = await _loadVerbList(catalog.irregularFile, language, false);
    final verbs = [...regularVerbs, ...irregularVerbs];

    _verbCache[language] = verbs;
    return verbs;
  }

  

  Future<List<Verb>> generatePracticeSet({
    required Language language, 
    required VerbTense tense,
    String? category,
    int setSize = 10
  }) async {
    final verbs = await fetchVerbs(language);
    final validVerbs = verbs.where((v) => v.hasTense(tense)).toList(growable: false);
    final filteredVerbs = category != null
        ? validVerbs.where((v) => v.category == category).toList(growable: false)
        : validVerbs;

    if (filteredVerbs.length <= setSize) {
      return filteredVerbs;
    }

    final practiceSet = filteredVerbs.toList();
    practiceSet.shuffle();
    return practiceSet.take(setSize).toList(growable: false);
  }

  void clearCache() {
    _verbCache.clear();
  }

  Future<VerbCatalog> _loadCatalog(Language language) async {
    final filePath = _verbFiles[language];
    if (filePath == null || filePath.isEmpty) {
      throw FormatException('No verb catalog configured for $language');
    }

    final String jsonString = await rootBundle.loadString(filePath);
    final decodedJson = json.decode(jsonString);

    if (decodedJson is Map<String, dynamic>) {
      return VerbCatalog.fromJson(decodedJson);
    }

    throw const FormatException('Verb catalog must be a JSON object.');
  }

  Future<List<Verb>> _loadVerbList(
    String filePath,
    Language language,
    bool isRegular,
  ) async {
    final String jsonString = await rootBundle.loadString(filePath);
    final decodedJson = json.decode(jsonString);

    if (isRegular) {
      if (decodedJson is! List<dynamic>) {
        throw FormatException('Regular verb asset must be a JSON array: $filePath');
      }

      return decodedJson
          .map((entry) => _buildRegularVerb(language, entry as String))
          .toList(growable: false);
    }

    if (decodedJson is Map<String, dynamic>) {
      return decodedJson.entries
          .map((entry) => _buildIrregularVerbFromForms(language, entry.key, entry.value))
          .toList(growable: false);
    }

    if (decodedJson is! List<dynamic>) {
      throw FormatException('Irregular verb asset must be a JSON array or object: $filePath');
    }

    return decodedJson
        .map((entry) => _buildIrregularVerb(language, entry))
        .toList(growable: false);
  }

  Verb _buildRegularVerb(Language language, String base) {
    return Verb(
      id: '${language.name}_$base',
      base: base,
      language: language.name,
      category: 'regular',
      isRegular: true,
      conjugationRules: _regularConjugationRules(language),
      spellingRules: _regularSpellingRules(language),
    );
  }

  Verb _buildIrregularVerb(Language language, dynamic entry) {
    if (entry is List<dynamic>) {
      return _buildLegacyIrregularVerb(language, entry);
    }

    if (entry is Map<String, dynamic> && entry.containsKey('base')) {
      return Verb.fromJson(entry);
    }

    throw FormatException('Unsupported irregular verb entry in $language: $entry');
  }

  Verb _buildIrregularVerbFromForms(Language language, String base, dynamic forms) {
    if (forms is! Map<String, dynamic>) {
      throw FormatException('Unsupported irregular forms for $base in $language');
    }

    if (language == Language.spanish) {
      return Verb(
        id: '${language.name}_$base',
        base: base,
        language: language.name,
        category: 'irregular',
        isRegular: false,
        conjugationRules: _regularConjugationRules(language),
        spellingRules: _regularSpellingRules(language),
        irregularForms: forms,
      );
    }

    throw FormatException('Unsupported irregular map format for $language');
  }

  // Removed legacy _buildIrregularVerbFromMap to avoid keeping
  // dead or ambiguous compatibility code. New code paths use
  // `Verb.fromJson`, `_buildIrregularVerbFromForms`, or
  // `_buildLegacyIrregularVerb` for legacy list formats.

  Verb _buildLegacyIrregularVerb(Language language, List<dynamic> entry) {
    if (language == Language.english) {
      final base = entry[0] as String;
      final pastSimple = entry.length > 1 ? entry[1] as String : '';
      return Verb(
        id: '${language.name}_$base',
        base: base,
        language: language.name,
        category: 'irregular',
        isRegular: false,
        conjugationRules: _regularConjugationRules(language),
        spellingRules: _regularSpellingRules(language),
        irregularForms: {
          'past_simple': {
            'affirmative': {
              'I': pastSimple,
              'you': pastSimple,
              'he/she/it': pastSimple,
              'we': pastSimple,
              'they': pastSimple,
            },
          },
        },
      );
    }

    if (language == Language.italian) {
      final base = entry[0] as String;
      const presentSubjects = ['io', 'tu', 'luiLei', 'noi', 'voi', 'loro'];
      const pastSubjects = ['io', 'tu', 'luiLei', 'noi', 'voi', 'loro'];
      const futureSubjects = ['io', 'tu', 'luiLei', 'noi', 'voi', 'loro'];

      return Verb(
        id: '${language.name}_$base',
        base: base,
        language: language.name,
        category: 'irregular',
        isRegular: false,
        conjugationRules: _regularConjugationRules(language),
        spellingRules: _regularSpellingRules(language),
        irregularForms: {
          'present_simple': {
            'affirmative': _zipSubjectsToValues(presentSubjects, entry.sublist(1, 7)),
          },
          'past_simple': {
            'affirmative': _zipSubjectsToValues(pastSubjects, entry.sublist(7, 13)),
          },
          'future_simple': {
            'affirmative': _zipSubjectsToValues(futureSubjects, entry.sublist(13, 19)),
          },
        },
      );
    }

    throw FormatException('Unsupported legacy irregular format for $language');
  }

  Map<String, dynamic> _regularConjugationRules(Language language) {
    switch (language) {
      case Language.english:
        return {
          'present_simple': {
            'affirmative': {
              'I': '{base}',
              'you': '{base}',
              'he/she/it': '{base}s',
              'we': '{base}',
              'they': '{base}',
            },
            'negative': {
              'I': 'do not {base}',
              'you': 'do not {base}',
              'he/she/it': 'does not {base}',
              'we': 'do not {base}',
              'they': 'do not {base}',
            },
            'question': {
              'I': 'do I {base}',
              'you': 'do you {base}',
              'he/she/it': 'does he/she/it {base}',
              'we': 'do we {base}',
              'they': 'do they {base}',
            },
          },
          'present_continuous': {
            'affirmative': {
              'I': 'am {base}ing',
              'you': 'are {base}ing',
              'he/she/it': 'is {base}ing',
              'we': 'are {base}ing',
              'they': 'are {base}ing',
            },
          },
          'past_simple': {
            'affirmative': {
              'I': '{base}ed',
              'you': '{base}ed',
              'he/she/it': '{base}ed',
              'we': '{base}ed',
              'they': '{base}ed',
            },
          },
          'past_continuous': {
            'affirmative': {
              'I': 'was {base}ing',
              'you': 'were {base}ing',
              'he/she/it': 'was {base}ing',
              'we': 'were {base}ing',
              'they': 'were {base}ing',
            },
          },
          'future_simple': {
            'affirmative': {
              'I': 'will {base}',
              'you': 'will {base}',
              'he/she/it': 'will {base}',
              'we': 'will {base}',
              'they': 'will {base}',
            },
          },
          'future_continuous': {
            'affirmative': {
              'I': 'will be {base}ing',
              'you': 'will be {base}ing',
              'he/she/it': 'will be {base}ing',
              'we': 'will be {base}ing',
              'they': 'will be {base}ing',
            },
          },
        };
      case Language.spanish:
        return {
          'present_simple': {
            'affirmative': {
              'yo': '{base}o',
              'tu': '{base}as',
              'elEllaUsted': '{base}a',
              'nosotros': '{base}amos',
              'vosotros': '{base}áis',
              'ellosEllasUstedes': '{base}an',
            },
          },
          'present_continuous': {
            'affirmative': {
              'yo': 'estoy {base}ando',
              'tu': 'estás {base}ando',
              'elEllaUsted': 'está {base}ando',
              'nosotros': 'estamos {base}ando',
              'vosotros': 'estáis {base}ando',
              'ellosEllasUstedes': 'están {base}ando',
            },
          },
          'past_simple': {
            'affirmative': {
              'yo': '{base}é',
              'tu': '{base}aste',
              'elEllaUsted': '{base}ó',
              'nosotros': '{base}amos',
              'vosotros': '{base}asteis',
              'ellosEllasUstedes': '{base}aron',
            },
          },
          'past_continuous': {
            'affirmative': {
              'yo': 'estaba {base}ando',
              'tu': 'estabas {base}ando',
              'elEllaUsted': 'estaba {base}ando',
              'nosotros': 'estábamos {base}ando',
              'vosotros': 'estabais {base}ando',
              'ellosEllasUstedes': 'estaban {base}ando',
            },
          },
          'future_simple': {
            'affirmative': {
              'yo': '{base}é',
              'tu': '{base}ás',
              'elEllaUsted': '{base}á',
              'nosotros': '{base}emos',
              'vosotros': '{base}éis',
              'ellosEllasUstedes': '{base}án',
            },
          },
          'future_continuous': {
            'affirmative': {
              'yo': 'estaré {base}ando',
              'tu': 'estarás {base}ando',
              'elEllaUsted': 'estará {base}ando',
              'nosotros': 'estaremos {base}ando',
              'vosotros': 'estaréis {base}ando',
              'ellosEllasUstedes': 'estarán {base}ando',
            },
          },
        };
      case Language.italian:
        return {
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
          'present_continuous': {
            'affirmative': {
              'io': 'sto {base}ando',
              'tu': 'stai {base}ando',
              'luiLei': 'sta {base}ando',
              'noi': 'stiamo {base}ando',
              'voi': 'state {base}ando',
              'loro': 'stanno {base}ando',
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
          'past_continuous': {
            'affirmative': {
              'io': 'ero {base}ando',
              'tu': 'eri {base}ando',
              'luiLei': 'era {base}ando',
              'noi': 'eravamo {base}ando',
              'voi': 'eravate {base}ando',
              'loro': 'erano {base}ando',
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
          'future_continuous': {
            'affirmative': {
              'io': 'sarò {base}ando',
              'tu': 'sarai {base}ando',
              'luiLei': 'sarà {base}ando',
              'noi': 'saremo {base}ando',
              'voi': 'sarete {base}ando',
              'loro': 'saranno {base}ando',
            },
          },
        };
    }
  }

  Map<String, dynamic> _regularSpellingRules(Language language) {
    switch (language) {
      case Language.english:
        return {
          'third_person_singular': 'default',
          'past_simple': 'default',
          'present_participle': 'default',
        };
      case Language.spanish:
        return {
          'default': 'regular',
        };
      case Language.italian:
        return {
          'default': 'regular',
        };
    }
  }

  Map<String, String> _zipSubjectsToValues(List<String> subjects, List<dynamic> values) {
    return Map<String, String>.fromIterables(
      subjects,
      values.map((value) => value as String),
    );
  }
}
