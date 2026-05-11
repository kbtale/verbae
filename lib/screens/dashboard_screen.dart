import 'package:flutter/material.dart';
import '../models/verb.dart';
import '../services/stats_service.dart';
import '../services/verb_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StatsService _statsService;
  final VerbService _verbService = VerbService();
  final Map<Language, Map<String, double>> _progressData = {};
  Map<String, int> _practiceTimes = {};
  Map<String, dynamic> _streakInfo = {'currentStreak': 0, 'lastPractice': DateTime.now()};
  bool _isLoading = true;
  bool _hasActivity = false;

  @override
  void initState() {
    super.initState();
    _initializeStats();
  }

  Future<void> _initializeStats() async {
    _statsService = await StatsService.create();
    if (!mounted) {
      return;
    }
    await _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);

    _progressData.clear();
    _practiceTimes = {};
    _streakInfo = {'currentStreak': 0, 'lastPractice': DateTime.now()};
    _hasActivity = false;

    // Load practice times
    _practiceTimes = await _statsService.getPracticeTimes();

    // Load streak info
    _streakInfo = await _statsService.getStreakInfo();

    // Load progress for each language
    for (final language in Language.values) {
      final verbs = await _verbService.fetchVerbs(language);
      final percentages = await _statsService.getPracticedVerbsPercentage(language, verbs);
      _progressData[language] = percentages;
    }

    _hasActivity = _practiceTimes.values.any((seconds) => seconds > 0) ||
        _progressData.values.any((languageProgress) =>
            languageProgress.values.any((progress) => progress > 0));

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
  }

  String _formatTenseName(String key) {
    final words = key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}');
    if (words.isEmpty) return key;
    return words[0].toUpperCase() + words.substring(1);
  }

  String _formatPracticeTime(int seconds) {
    if (seconds == 0) return 'No practice yet';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  Widget _buildStreakInfo() {
    final streak = _streakInfo['currentStreak'] as int;
    final lastPractice = _streakInfo['lastPractice'] as DateTime;
    final today = DateTime.now();
    final lastPracticeDay = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final daysSinceLastPractice = todayDay.difference(lastPracticeDay).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Current Streak: $streak days',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (daysSinceLastPractice > 0)
              Text(
                'Last practice: ${daysSinceLastPractice == 1 ? 'yesterday' : '$daysSinceLastPractice days ago'}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTimeCard() {
    if (_practiceTimes.isEmpty) {
      return const Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No practice time recorded yet'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._practiceTimes.entries.map((entry) {
              final language = entry.key;
              final timeInSeconds = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language[0].toUpperCase() + language.substring(1)),
                    Text(_formatPracticeTime(timeInSeconds)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String category,
    required double progress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTenseName(category),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 70
                  ? Colors.green
                  : progress > 40
                      ? Colors.orange
                      : Theme.of(context).colorScheme.error,
            ),
          ),
          Text('${progress.toStringAsFixed(1)}% verbs practiced'),
        ],
      ),
    );
  }

  Widget _buildLanguageProgressCards() {
    if (!_hasActivity) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Progress will appear here after your first practice session.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a language and tense to start building stats.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _progressData.entries.map((languageEntry) {
        final language = languageEntry.key;
        final tensesProgress = languageEntry.value;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.name[0].toUpperCase() + language.name.substring(1),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...tensesProgress.entries.map((entry) {
                  return _buildProgressBar(
                    category: entry.key,
                    progress: entry.value,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          children: [
            _buildStreakInfo(),
            _buildPracticeTimeCard(),
            _buildLanguageProgressCards(),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
