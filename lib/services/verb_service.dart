import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/verb.dart';

class VerbService {
  final Map<Language, String> _verbFiles = {
    Language.english: 'assets/verbs/english.json',
    Language.spanish: 'assets/verbs/spanish.json',
    Language.italian: 'assets/verbs/italian.json',
  };

  final Map<Language, List<Verb>> _verbCache = {};

  Future<List<Verb>> fetchVerbs(Language language) async {
    if (_verbCache.containsKey(language)) {
      return _verbCache[language]!;
    }

    final String jsonString = await rootBundle.loadString(_verbFiles[language]!);
    final List<dynamic> verbsJson = json.decode(jsonString);
    
    final verbs = verbsJson.map((verbJson) => Verb.fromJson(verbJson)).toList();
    _verbCache[language] = verbs;
    return verbs;
  }

  Future<List<Verb>> generatePracticeSet({
    required Language language, 
    String? category,
    int setSize = 10
  }) async {
    final verbs = await fetchVerbs(language);
    if (category != null) {
      return verbs.where((v) => v.category == category).toList();
    }
    // Shuffle and take a subset
    verbs.shuffle();
    return verbs.take(setSize).toList();
  }

  void clearCache() {
    _verbCache.clear();
  }
}
