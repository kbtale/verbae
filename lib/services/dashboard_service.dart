import 'package:flutter/foundation.dart';

import 'verb_service.dart';
import 'stats_service.dart';
import '../models/verb.dart';

class DashboardService {
  final StatsService _stats;
  final VerbService _verbs;

  DashboardService(this._stats, this._verbs);

  Future<Map<Language, Map<String, double>>> aggregateProgress() async {
    final Map<Language, Map<String, double>> result = {};

    for (final language in Language.values) {
      try {
        final verbs = await _verbs.fetchVerbs(language);
        if (verbs.isEmpty) {
          result[language] = {};
          continue;
        }

        final percentages = await _stats.getPracticedVerbsPercentage(language, verbs);
        result[language] = percentages;
      } catch (e, st) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('DashboardService.aggregateProgress error for $language: $e\n$st');
        }
        result[language] = {};
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> computeMetrics() async {
    try {
      final practiceTimes = await _stats.getPracticeTimes();
      final streakInfo = await _stats.getStreakInfo();
      final progress = await aggregateProgress();

      double total = 0.0;
      int count = 0;
      for (final langMap in progress.values) {
        for (final v in langMap.values) {
          total += v;
          count++;
        }
      }

      final overallCoverage = count == 0 ? 0.0 : total / count;

      return {
        'practiceTimes': practiceTimes,
        'streakInfo': streakInfo,
        'overallCoverage': overallCoverage,
        'perLanguageProgress': progress,
      };
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DashboardService.computeMetrics error: $e\n$st');
      }
      return {
        'practiceTimes': <String, int>{},
        'streakInfo': {'currentStreak': 0, 'lastPractice': DateTime.now()},
        'overallCoverage': 0.0,
        'perLanguageProgress': <Language, Map<String, double>>{},
      };
    }
  }
}
