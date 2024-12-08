import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verb.dart';

class StatsService {
  final SharedPreferences _prefs;
  static const String _statsKey = 'verb_stats';
  static const String _streakKey = 'practice_streak';
  static const String _lastPracticeKey = 'last_practice';
  static const String _practiceTimeKey = 'practice_time';
  static const String _verbsPracticedKey = 'verbs_practiced';

  StatsService(this._prefs);

  static Future<StatsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StatsService(prefs);
  }

  // Record practice session
  Future<void> recordPractice({
    required Language language,
    required VerbTense tense,
    required bool isCorrect,
    required String verbId,
    required int practiceTimeSeconds,
  }) async {
    final stats = await getStats();
    final key = '${language.name}_${tense.name}';
    
    if (!stats.containsKey(key)) {
      stats[key] = {'total': 0, 'correct': 0};
    }
    
    stats[key]!['total'] = (stats[key]!['total'] ?? 0) + 1;
    if (isCorrect) {
      stats[key]!['correct'] = (stats[key]!['correct'] ?? 0) + 1;
    }

    // Record practiced verbs
    final practicedVerbs = await getPracticedVerbs();
    if (!practicedVerbs.containsKey(key)) {
      practicedVerbs[key] = <String>{};
    }
    practicedVerbs[key]!.add(verbId);
    await _savePracticedVerbs(practicedVerbs);

    // Update practice time
    final practiceTimes = await getPracticeTimes();
    if (!practiceTimes.containsKey(language.name)) {
      practiceTimes[language.name] = 0;
    }
    practiceTimes[language.name] = practiceTimes[language.name]! + practiceTimeSeconds;
    await _prefs.setString(_practiceTimeKey, jsonEncode(practiceTimes));

    // Update streak
    await _updateStreak();

    // Save all stats
    await _prefs.setString(_statsKey, jsonEncode(stats));
  }

  // Get practiced verbs percentage for each tense
  Future<Map<String, double>> getPracticedVerbsPercentage(Language language, List<Verb> allVerbs) async {
    final practicedVerbs = await getPracticedVerbs();
    Map<String, double> percentages = {};
    
    for (final tense in VerbTense.values) {
      final key = '${language.name}_${tense.name}';
      final verbsForTense = allVerbs.where((v) => v.hasTense(tense)).length;
      
      if (verbsForTense == 0) continue;
      
      final practiced = practicedVerbs[key]?.length ?? 0;
      percentages[tense.name] = (practiced / verbsForTense) * 100;
    }
    
    return percentages;
  }

  // Get practice times for each language
  Future<Map<String, int>> getPracticeTimes() async {
    final String? timesJson = _prefs.getString(_practiceTimeKey);
    if (timesJson == null) return {};
    return Map<String, int>.from(jsonDecode(timesJson));
  }

  // Get streak information
  Future<Map<String, dynamic>> getStreakInfo() async {
    final lastPracticeMs = _prefs.getInt(_lastPracticeKey);
    final streak = _prefs.getInt(_streakKey) ?? 0;
    
    final lastPractice = lastPracticeMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(lastPracticeMs)
        : DateTime.now();
        
    return {
      'currentStreak': streak,
      'lastPractice': lastPractice,
    };
  }

  // Update streak
  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final lastPracticeMs = _prefs.getInt(_lastPracticeKey);
    
    if (lastPracticeMs == null) {
      // First practice
      await _prefs.setInt(_streakKey, 1);
      await _prefs.setInt(_lastPracticeKey, now.millisecondsSinceEpoch);
      return;
    }

    final lastPractice = DateTime.fromMillisecondsSinceEpoch(lastPracticeMs);
    final lastPracticeDay = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(lastPracticeDay).inDays;

    if (difference == 0) {
      // Same day, don't update streak
      return;
    } else if (difference == 1) {
      // Next day, increment streak
      final currentStreak = _prefs.getInt(_streakKey) ?? 0;
      await _prefs.setInt(_streakKey, currentStreak + 1);
    } else {
      // More than a day gap, reset streak
      await _prefs.setInt(_streakKey, 1);
    }
    
    await _prefs.setInt(_lastPracticeKey, now.millisecondsSinceEpoch);
  }

  // Get practiced verbs
  Future<Map<String, Set<String>>> getPracticedVerbs() async {
    final String? verbsJson = _prefs.getString(_verbsPracticedKey);
    if (verbsJson == null) return {};
    
    final Map<String, dynamic> decoded = jsonDecode(verbsJson);
    return Map<String, Set<String>>.from(
      decoded.map((key, value) => MapEntry(
        key,
        Set<String>.from(value as List),
      )),
    );
  }

  // Save practiced verbs
  Future<void> _savePracticedVerbs(Map<String, Set<String>> practicedVerbs) async {
    // Convert Sets to Lists for JSON serialization
    final jsonMap = practicedVerbs.map((key, value) => 
      MapEntry(key, value.toList())
    );
    await _prefs.setString(_verbsPracticedKey, jsonEncode(jsonMap));
  }

  // Get basic stats
  Future<Map<String, Map<String, int>>> getStats() async {
    final String? statsJson = _prefs.getString(_statsKey);
    if (statsJson == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(statsJson);
    return Map<String, Map<String, int>>.from(
      decoded.map((key, value) => MapEntry(
        key,
        Map<String, int>.from(value as Map),
      )),
    );
  }

  // Get accuracy for a specific language and tense
  Future<double> getAccuracy(Language language, VerbTense tense) async {
    final stats = await getStats();
    final key = '${language.name}_${tense.name}';
    
    if (!stats.containsKey(key) || stats[key]!['total'] == 0) {
      return 0.0;
    }

    return (stats[key]!['correct'] ?? 0) / stats[key]!['total']! * 100;
  }

  // Clear all stats
  Future<void> clearStats() async {
    await _prefs.remove(_statsKey);
    await _prefs.remove(_streakKey);
    await _prefs.remove(_lastPracticeKey);
    await _prefs.remove(_practiceTimeKey);
    await _prefs.remove(_verbsPracticedKey);
  }
}
