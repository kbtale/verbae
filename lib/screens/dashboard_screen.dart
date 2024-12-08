import 'package:flutter/material.dart';
import '../models/verb.dart';
import '../services/stats_service.dart';
import '../services/verb_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StatsService _statsService;
  final VerbService _verbService = VerbService();
  Map<Language, Map<String, double>> _progressData = {};
  Map<String, int> _practiceTimes = {};
  Map<String, dynamic> _streakInfo = {'currentStreak': 0, 'lastPractice': DateTime.now()};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStats();
  }

  Future<void> _initializeStats() async {
    _statsService = await StatsService.create();
    await _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

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

    setState(() => _isLoading = false);
  }

  String _formatPracticeTime(int seconds) {
    if (seconds == 0) return 'No practice yet';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h ${minutes} min';
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
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Current Streak: $streak days',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (daysSinceLastPractice > 0)
              Text(
                'Last practice: ${daysSinceLastPractice == 1 ? 'yesterday' : '$daysSinceLastPractice days ago'}',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTimeCard() {
    if (_practiceTimes.isEmpty) {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No practice time recorded yet'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            ..._practiceTimes.entries.map((entry) {
              final language = entry.key;
              final timeInSeconds = entry.value;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.toUpperCase()),
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
            category.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 70
                  ? Colors.green
                  : progress > 40
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
          Text('${progress.toStringAsFixed(1)}% verbs practiced'),
        ],
      ),
    );
  }

  Widget _buildLanguageProgressCards() {
    return Column(
      children: _progressData.entries.map((languageEntry) {
        final language = languageEntry.key;
        final tensesProgress = languageEntry.value;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.toString().split('.').last.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
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
        appBar: AppBar(title: Text('Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          children: [
            _buildStreakInfo(),
            _buildPracticeTimeCard(),
            _buildLanguageProgressCards(),
          ],
        ),
      ),
    );
  }
}
