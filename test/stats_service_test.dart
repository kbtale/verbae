import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/services/stats_service.dart';
import 'package:lingua_verb_master/models/verb.dart';

Verb _makeVerb(String id, {bool hasPresent = true, bool hasPast = true, bool hasFuture = true}) {
  final rules = <String, dynamic>{};
  if (hasPresent) {
    rules['present_simple'] = {'affirmative': {'I': '{base}'}};
  }
  if (hasPast) {
    rules['past_simple'] = {'affirmative': {'I': '{base}ed'}};
  }
  if (hasFuture) {
    rules['future_simple'] = {'affirmative': {'I': 'will {base}'}};
  }
  return Verb(
    id: id,
    base: id,
    language: 'english',
    category: 'regular',
    isRegular: true,
    conjugationRules: rules,
    spellingRules: const {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stats service returns empty maps for malformed stored data', () async {
    SharedPreferences.setMockInitialValues({
      'practice_time': '{bad json',
      'verbs_practiced': '123',
      'verb_stats': '[1,2,3]',
    });

    final service = await StatsService.create();

    expect(await service.getPracticeTimes(), isEmpty);
    expect(await service.getPracticedVerbs(), isEmpty);
    expect(await service.getStats(), isEmpty);
  });

  test('recordPractice increments total and correct counts', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 30,
    );

    final stats = await service.getStats();
    const key = 'english_presentSimple';
    expect(stats[key]!['total'], 1);
    expect(stats[key]!['correct'], 1);
  });

  test('recordPractice increments counts across multiple submissions', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 30,
    );
    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: false,
      verbId: 'v2',
      practiceTimeSeconds: 45,
    );

    final stats = await service.getStats();
    const key = 'english_presentSimple';
    expect(stats[key]!['total'], 2);
    expect(stats[key]!['correct'], 1);
  });

  test('practiced verbs set adds and retrieves unique IDs', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 10,
    );
    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 20,
    );
    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: false,
      verbId: 'v2',
      practiceTimeSeconds: 15,
    );

    final practiced = await service.getPracticedVerbs();
    const key = 'english_presentSimple';
    expect(practiced[key], contains('v1'));
    expect(practiced[key], contains('v2'));
    expect(practiced[key]!.length, 2);
  });

  test('getPracticedVerbsPercentage returns correct percentage', () async {
    SharedPreferences.setMockInitialValues({
      'verbs_practiced': jsonEncode({
        'english_presentSimple': ['v1'],
        'english_pastSimple': ['v1', 'v3'],
      }),
    });
    final service = await StatsService.create();

    final verbs = [
      _makeVerb('v1', hasPresent: true, hasPast: true),
      _makeVerb('v2', hasPresent: true, hasPast: false, hasFuture: false),
      _makeVerb('v3', hasPresent: false, hasPast: true, hasFuture: false),
    ];

    final percentages = await service.getPracticedVerbsPercentage(Language.english, verbs);

    expect(percentages['presentSimple'], closeTo(50.0, 0.01));
    expect(percentages['pastSimple'], closeTo(100.0, 0.01));
  });

  test('getAccuracy returns 0 when no data present', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    final accuracy = await service.getAccuracy(Language.english, VerbTense.presentSimple);

    expect(accuracy, 0.0);
  });

  test('getAccuracy returns correct percentage with data', () async {
    SharedPreferences.setMockInitialValues({
      'verb_stats': jsonEncode({
        'english_presentSimple': {'total': 4, 'correct': 3},
      }),
    });
    final service = await StatsService.create();

    final accuracy = await service.getAccuracy(Language.english, VerbTense.presentSimple);

    expect(accuracy, closeTo(75.0, 0.01));
  });

  test('streak starts at 1 on first practice', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 30,
    );

    final streakInfo = await service.getStreakInfo();
    expect(streakInfo['currentStreak'], 1);
  });

  test('same-day practice does not change streak', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'practice_streak': 3,
      'last_practice': now.millisecondsSinceEpoch,
    });
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 10,
    );

    final streakInfo = await service.getStreakInfo();
    expect(streakInfo['currentStreak'], 3);
  });

  test('next-day practice increments streak', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'practice_streak': 5,
      'last_practice': yesterday.millisecondsSinceEpoch,
    });
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 10,
    );

    final streakInfo = await service.getStreakInfo();
    expect(streakInfo['currentStreak'], 6);
  });

  test('gap of more than one day resets streak to 1', () async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    SharedPreferences.setMockInitialValues({
      'practice_streak': 10,
      'last_practice': threeDaysAgo.millisecondsSinceEpoch,
    });
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 10,
    );

    final streakInfo = await service.getStreakInfo();
    expect(streakInfo['currentStreak'], 1);
  });

  test('practice time accumulates across sessions', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.presentSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 60,
    );
    await service.recordPractice(
      language: Language.english,
      tense: VerbTense.pastSimple,
      isCorrect: true,
      verbId: 'v2',
      practiceTimeSeconds: 45,
    );
    await service.recordPractice(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      isCorrect: false,
      verbId: 'v3',
      practiceTimeSeconds: 90,
    );

    final times = await service.getPracticeTimes();
    expect(times['english'], 105);
    expect(times['italian'], 90);
  });

  test('clearStats removes all keys', () async {
    SharedPreferences.setMockInitialValues({
      'practice_streak': 7,
      'last_practice': DateTime.now().millisecondsSinceEpoch,
      'practice_time': jsonEncode({'english': 120}),
      'verbs_practiced': jsonEncode({'english_presentSimple': ['v1']}),
      'verb_stats': jsonEncode({'english_presentSimple': {'total': 5, 'correct': 4}}),
    });
    final service = await StatsService.create();

    await service.clearStats();

    expect(await service.getPracticeTimes(), isEmpty);
    expect(await service.getPracticedVerbs(), isEmpty);
    expect(await service.getStats(), isEmpty);
    final streakInfo = await service.getStreakInfo();
    expect(streakInfo['currentStreak'], 0);
  });

  test('getStats returns empty map when no data stored', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    final stats = await service.getStats();

    expect(stats, isEmpty);
  });

  test('getPracticeTimes round-trips correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StatsService.create();

    await service.recordPractice(
      language: Language.spanish,
      tense: VerbTense.futureSimple,
      isCorrect: true,
      verbId: 'v1',
      practiceTimeSeconds: 120,
    );

    // Re-read to verify persistence
    final service2 = await StatsService.create();
    final times = await service2.getPracticeTimes();

    expect(times['spanish'], 120);
  });
}
