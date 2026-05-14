import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/screens/dashboard_screen.dart';
import 'package:lingua_verb_master/services/stats_service.dart';
import 'package:lingua_verb_master/services/verb_service.dart';

class _FakeStatsService extends StatsService {
  _FakeStatsService(SharedPreferences prefs) : super(prefs);

  @override
  Future<Map<String, int>> getPracticeTimes() async => {};

  @override
  Future<Map<String, dynamic>> getStreakInfo() async => {
        'currentStreak': 0,
        'lastPractice': DateTime.now(),
      };

  @override
  Future<Map<String, double>> getPracticedVerbsPercentage(Language language, List<Verb> allVerbs) async => {};
}

class _FakeVerbService extends VerbService {
  @override
  Future<List<Verb>> fetchVerbs(Language language) async => [
        Verb(
          id: 'italian_parlare',
          base: 'parlare',
          language: 'italian',
          category: 'regular',
          isRegular: true,
          conjugationRules: {
            'present_simple': {
              'affirmative': {'io': '{base}o'},
            },
          },
          spellingRules: const {'default': 'regular'},
        ),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard screen starts in loading state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('dashboard shows first-run empty state when there is no activity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          statsService: _FakeStatsService(prefs),
          verbService: _FakeVerbService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No practice data yet'), findsOneWidget);
    expect(find.textContaining('Complete your first practice session'), findsOneWidget);
  });
}