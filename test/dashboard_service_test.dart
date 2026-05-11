import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/services/stats_service.dart';
import 'package:lingua_verb_master/services/dashboard_service.dart';
import 'package:lingua_verb_master/services/verb_service.dart';
import 'package:lingua_verb_master/models/verb.dart';

class _FakeVerbService extends VerbService {
  final Map<Language, List<Verb>> data;

  _FakeVerbService(this.data);

  @override
  Future<List<Verb>> fetchVerbs(Language language) async => data[language] ?? <Verb>[];
}

String _tenseKey(VerbTense tense) {
  switch (tense) {
    case VerbTense.presentSimple:
      return 'present_simple';
    case VerbTense.presentContinuous:
      return 'present_continuous';
    case VerbTense.pastSimple:
      return 'past_simple';
    case VerbTense.pastContinuous:
      return 'past_continuous';
    case VerbTense.futureSimple:
      return 'future_simple';
    case VerbTense.futureContinuous:
      return 'future_continuous';
  }
}

Verb _buildVerb({
  required String id,
  required Language language,
  required List<VerbTense> tenses,
}) {
  final Map<String, dynamic> conjugationRules = {};
  for (final tense in tenses) {
    conjugationRules[_tenseKey(tense)] = {
      'affirmative': {'I': 'x'},
    };
  }

  return Verb(
    id: id,
    base: id,
    language: language.name,
    category: 'regular',
    isRegular: true,
    conjugationRules: conjugationRules,
    spellingRules: {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeMetrics returns defaults when no data present', () async {
    SharedPreferences.setMockInitialValues({});
    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FakeVerbService({}));

    final metrics = await dashboard.computeMetrics();

    expect(metrics['practiceTimes'], isA<Map<String, int>>());
    expect(metrics['overallCoverage'], equals(0.0));
    expect(metrics['perLanguageProgress'], isA<Map<Language, Map<String, double>>>());
    expect(metrics['perLanguageAccuracy'], isA<Map<Language, Map<String, double>>>());
  });

  test('aggregateProgress returns empty maps when verbs list empty', () async {
    SharedPreferences.setMockInitialValues({});
    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FakeVerbService({}));

    final progress = await dashboard.aggregateProgress();

    for (final language in Language.values) {
      expect(progress.containsKey(language), isTrue);
      expect(progress[language], isEmpty);
    }
  });

  test('computeMetrics returns weighted coverage and accuracy', () async {
    SharedPreferences.setMockInitialValues({
      'verbs_practiced': jsonEncode({
        'english_presentSimple': ['v1'],
        'english_pastSimple': ['v1', 'v3'],
      }),
      'verb_stats': jsonEncode({
        'english_presentSimple': {'total': 2, 'correct': 1},
        'english_pastSimple': {'total': 3, 'correct': 2},
      }),
    });

    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);

    final verbs = <Verb>[
      _buildVerb(
        id: 'v1',
        language: Language.english,
        tenses: [VerbTense.presentSimple, VerbTense.pastSimple],
      ),
      _buildVerb(
        id: 'v2',
        language: Language.english,
        tenses: [VerbTense.presentSimple],
      ),
      _buildVerb(
        id: 'v3',
        language: Language.english,
        tenses: [VerbTense.pastSimple],
      ),
    ];

    final dashboard = DashboardService(
      stats,
      _FakeVerbService({Language.english: verbs}),
    );

    final metrics = await dashboard.computeMetrics();
    final progress = metrics['perLanguageProgress'] as Map<Language, Map<String, double>>;
    final accuracy = metrics['perLanguageAccuracy'] as Map<Language, Map<String, double>>;

    expect(metrics['overallCoverage'], closeTo(75.0, 0.01));
    expect(progress[Language.english]!['presentSimple'], closeTo(50.0, 0.01));
    expect(progress[Language.english]!['pastSimple'], closeTo(100.0, 0.01));
    expect(accuracy[Language.english]!['presentSimple'], closeTo(50.0, 0.01));
    expect(accuracy[Language.english]!['pastSimple'], closeTo(66.6667, 0.01));
  });

  test('computeMetrics handles VerbService fetchVerbs throwing', () async {
    SharedPreferences.setMockInitialValues({});
    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FailingVerbService());

    final metrics = await dashboard.computeMetrics();

    expect(metrics['overallCoverage'], equals(0.0));
    expect(metrics['perLanguageProgress'], isA<Map<Language, Map<String, double>>>());
    expect(metrics['perLanguageAccuracy'], isA<Map<Language, Map<String, double>>>());
  });

  test('aggregateProgress returns empty maps when fetchVerbs throws', () async {
    SharedPreferences.setMockInitialValues({});
    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FailingVerbService());

    final progress = await dashboard.aggregateProgress();

    for (final language in Language.values) {
      expect(progress.containsKey(language), isTrue);
      expect(progress[language], isEmpty);
    }
  });

  test('computeMetrics clamps practiced count to total available', () async {
    SharedPreferences.setMockInitialValues({
      'verbs_practiced': jsonEncode({
        'english_presentSimple': ['v1', 'v2', 'v3', 'v4'],
      }),
      'verb_stats': jsonEncode({
        'english_presentSimple': {'total': 5, 'correct': 3},
      }),
    });

    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);

    final verbs = <Verb>[
      _buildVerb(
        id: 'v1',
        language: Language.english,
        tenses: [VerbTense.presentSimple],
      ),
    ];

    final dashboard = DashboardService(
      stats,
      _FakeVerbService({Language.english: verbs}),
    );

    final metrics = await dashboard.computeMetrics();
    final progress = metrics['perLanguageProgress'] as Map<Language, Map<String, double>>;

    expect(progress[Language.english]!['presentSimple'], closeTo(100.0, 0.01));
  });

  test('computeMetrics returns zero coverage when totalAvailable is zero', () async {
    SharedPreferences.setMockInitialValues({
      'verbs_practiced': jsonEncode({
        'english_presentSimple': ['v1'],
      }),
    });

    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FakeVerbService({}));

    final metrics = await dashboard.computeMetrics();

    expect(metrics['overallCoverage'], equals(0.0));
  });
}

class _FailingVerbService extends VerbService {
  @override
  Future<List<Verb>> fetchVerbs(Language language) async {
    throw Exception('Simulated load failure');
  }
}
