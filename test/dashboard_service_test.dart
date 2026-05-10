import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verbae/services/stats_service.dart';
import 'package:verbae/services/dashboard_service.dart';
import 'package:verbae/models/verb.dart';

class _FakeVerbService {
  Future<List<Verb>> fetchVerbs(Language language) async => <Verb>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeMetrics returns defaults when no data present', () async {
    SharedPreferences.setMockInitialValues({});
    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FakeVerbService());

    final metrics = await dashboard.computeMetrics();

    expect(metrics['practiceTimes'], isA<Map<String, int>>());
    expect(metrics['overallCoverage'], equals(0.0));
    expect(metrics['perLanguageProgress'], isA<Map<Language, Map<String, double>>>());
  });

  test('aggregateProgress returns empty maps when verbs list empty', () async {
    SharedPreferences.setMockInitialValues({});
    final statsPrefs = await SharedPreferences.getInstance();
    final stats = StatsService(statsPrefs);
    final dashboard = DashboardService(stats, _FakeVerbService());

    final progress = await dashboard.aggregateProgress();

    for (final language in Language.values) {
      expect(progress.containsKey(language), isTrue);
      expect(progress[language], isEmpty);
    }
  });
}
