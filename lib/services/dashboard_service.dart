import 'dart:developer' as developer;

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
          developer.log('aggregateProgress error for $language',
            name: 'DashboardService', error: e, stackTrace: st,);
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
      final aggregation = await _aggregateMetrics();

      return {
        'practiceTimes': practiceTimes,
        'streakInfo': streakInfo,
        'overallCoverage': aggregation.overallCoverage,
        'perLanguageProgress': aggregation.progress,
        'perLanguageAccuracy': aggregation.accuracy,
      };
    } catch (e, st) {
      if (kDebugMode) {
        developer.log('computeMetrics error',
          name: 'DashboardService', error: e, stackTrace: st);
      }
      return {
        'practiceTimes': <String, int>{},
        'streakInfo': {'currentStreak': 0, 'lastPractice': DateTime.now()},
        'overallCoverage': 0.0,
        'perLanguageProgress': <Language, Map<String, double>>{},
        'perLanguageAccuracy': <Language, Map<String, double>>{},
      };
    }
  }

  Future<_DashboardAggregation> _aggregateMetrics() async {
    final practicedVerbs = await _stats.getPracticedVerbs();
    final stats = await _stats.getStats();

    final Map<Language, Map<String, double>> progress = {};
    final Map<Language, Map<String, double>> accuracy = {};

    int totalAvailable = 0;
    int totalPracticed = 0;

    for (final language in Language.values) {
      final Map<String, double> languageProgress = {};
      final Map<String, double> languageAccuracy = {};

      try {
        final verbs = await _verbs.fetchVerbs(language);
        if (verbs.isEmpty) {
          progress[language] = {};
          accuracy[language] = {};
          continue;
        }

        for (final tense in VerbTense.values) {
          final key = '${language.name}_${tense.name}';
          final total = verbs.where((v) => v.hasTense(tense)).length;
          if (total == 0) continue;

          final int practiced = practicedVerbs[key]?.length ?? 0;
          final int practicedClamped = practiced > total ? total : practiced;

          languageProgress[tense.name] = (practicedClamped / total) * 100;

          totalAvailable += total;
          totalPracticed += practicedClamped;

          final statsEntry = stats[key];
          final totalCount = statsEntry?['total'] ?? 0;
          final correctCount = statsEntry?['correct'] ?? 0;
          final accuracyValue = totalCount == 0 ? 0.0 : (correctCount / totalCount) * 100;

          languageAccuracy[tense.name] = accuracyValue;
        }
      } catch (e, st) {
        if (kDebugMode) {
          developer.log('_aggregateMetrics error for $language',
            name: 'DashboardService', error: e, stackTrace: st,);
        }
      }

      progress[language] = languageProgress;
      accuracy[language] = languageAccuracy;
    }

    final overallCoverage = totalAvailable == 0 ? 0.0 : (totalPracticed / totalAvailable) * 100;

    return _DashboardAggregation(
      progress: progress,
      accuracy: accuracy,
      overallCoverage: overallCoverage,
    );
  }

}

class _DashboardAggregation {
  final Map<Language, Map<String, double>> progress;
  final Map<Language, Map<String, double>> accuracy;
  final double overallCoverage;

  _DashboardAggregation({
    required this.progress,
    required this.accuracy,
    required this.overallCoverage,
  });
}
