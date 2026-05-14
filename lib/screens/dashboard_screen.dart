import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/verb.dart';
import '../services/stats_service.dart';
import '../services/verb_service.dart';
import '../widgets/app_state_view.dart';

class DashboardScreen extends StatefulWidget {
  final StatsService? statsService;
  final VerbService? verbService;

  const DashboardScreen({super.key, this.statsService, this.verbService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StatsService _statsService;
  late VerbService _verbService;
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
    _statsService = widget.statsService ?? await StatsService.create();
    _verbService = widget.verbService ?? VerbService();
    if (!mounted) return;
    await _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _progressData.clear();
    _practiceTimes = {};
    _streakInfo = {'currentStreak': 0, 'lastPractice': DateTime.now()};
    _hasActivity = false;

    _practiceTimes = await _statsService.getPracticeTimes();
    _streakInfo = await _statsService.getStreakInfo();

    for (final language in Language.values) {
      try {
        final verbs = await _verbService.fetchVerbs(language);
        final percentages = await _statsService.getPracticedVerbsPercentage(language, verbs);
        _progressData[language] = percentages;
      } catch (_) {
        _progressData[language] = {};
      }
    }

    _hasActivity = _practiceTimes.values.any((seconds) => seconds > 0) ||
        _progressData.values.any((languageProgress) =>
            languageProgress.values.any((progress) => progress > 0),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _formatPracticeTime(int seconds) {
    if (seconds == 0) return 'No practice yet';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '$hours h $minutes min';
    return '$minutes min';
  }

  String _formatTenseName(String key) {
    final words = key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}');
    if (words.isEmpty) return key;
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          scrolledUnderElevation: 1,
        ),
        body: const AppStateView(
          title: 'Loading dashboard',
          message: 'Fetching your practice stats and progress.',
          isLoading: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _hasActivity
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    _buildStreakCard(cs, tt),
                    const SizedBox(height: 16),
                    _buildPracticeTimeCard(cs, tt),
                    const SizedBox(height: 24),
                    _buildLanguageProgressCards(cs, tt),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            )
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return AppStateView(
      title: 'No practice data yet',
      message: 'Complete your first practice session to start tracking progress.',
      icon: Icons.school_rounded,
    );
  }

  Widget _buildStreakCard(ColorScheme cs, TextTheme tt) {
    final streak = _streakInfo['currentStreak'] as int;
    final lastPractice = _streakInfo['lastPractice'] as DateTime;
    final today = DateTime.now();
    final lastPracticeDay = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final daysSinceLastPractice = todayDay.difference(lastPracticeDay).inDays;

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.local_fire_department_rounded, color: cs.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak day${streak == 1 ? '' : 's'}',
                    style: tt.headlineMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Current streak',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (daysSinceLastPractice > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysSinceLastPractice == 1 ? 'yesterday' : '${daysSinceLastPractice}d ago',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTimeCard(ColorScheme cs, TextTheme tt) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text('Practice Time', style: tt.titleSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(height: 16),
            if (_practiceTimes.isEmpty)
              Text('No practice time recorded yet', style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
            ..._practiceTimes.entries.map((entry) {
              final language = entry.key;
              final timeInSeconds = entry.value;
              final name = language[0].toUpperCase() + language.substring(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: tt.bodyLarge)),
                    Text(_formatPracticeTime(timeInSeconds), style: tt.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageProgressCards(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text('Progress', style: tt.titleSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 12),
        ..._progressData.entries.where((e) => e.value.isNotEmpty).map((languageEntry) {
          final language = languageEntry.key;
          final tensesProgress = languageEntry.value;
          final name = language.name[0].toUpperCase() + language.name.substring(1);

          return Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ...tensesProgress.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTenseName(entry.key), style: tt.bodySmall),
                              Text(
                                '${entry.value.toStringAsFixed(0)}%',
                                style: tt.labelMedium?.copyWith(
                                  color: entry.value > 70
                                      ? AppColors.stormyTeal
                                      : entry.value > 30
                                          ? cs.tertiary
                                          : cs.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value / 100,
                              minHeight: 8,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                entry.value > 70
                                    ? AppColors.stormyTeal
                                    : entry.value > 30
                                        ? cs.tertiary
                                        : cs.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
