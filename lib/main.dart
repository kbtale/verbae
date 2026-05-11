import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/practice_screen.dart';
import 'screens/dashboard_screen.dart';
import 'models/verb.dart';
import 'services/verb_service.dart';
import 'theme/app_theme.dart';

void main() {
  FlutterError.onError = (details) {
    developer.log('Flutter framework error',
      name: 'VerbaeApp', error: details.exception, stackTrace: details.stack,);
  };
  runApp(const VerbaeApp());
}

class VerbaeApp extends StatelessWidget {
  const VerbaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verbae',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VerbTense _selectedTense = VerbTense.presentSimple;
  final VerbService _verbService = VerbService();
  final Map<Language, Set<VerbTense>> _availableTenses = {};
  bool _showWelcomeCard = false;
  bool _tensesLoading = true;
  static const String _onboardingKey = 'onboarding_shown';

  static const _languageIcons = {
    Language.italian: '🇮🇹',
    Language.english: '🇬🇧',
    Language.spanish: '🇪🇸',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailableTenses();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_onboardingKey) ?? false;
    if (!mounted) return;
    setState(() => _showWelcomeCard = !shown);
  }

  Future<void> _dismissWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    if (!mounted) return;
    setState(() => _showWelcomeCard = false);
  }

  Future<void> _loadAvailableTenses() async {
    for (var language in Language.values) {
      final verbs = await _verbService.fetchVerbs(language);
      Set<VerbTense> tenses = {};
      for (var verb in verbs) {
        tenses.addAll(verb.tenses.keys);
      }
      if (!mounted) return;
      setState(() => _availableTenses[language] = tenses);
    }
    if (!mounted) return;
    setState(() => _tensesLoading = false);
  }

  bool _isTenseAvailable(Language language) {
    return _availableTenses[language]?.contains(_selectedTense) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verbae',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                if (_showWelcomeCard) _buildWelcomeCard(context),

                const SizedBox(height: 8),

                Center(
                  child: Image.asset(
                    'assets/images/verbae-high-resolution-logo-transparent.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Choose a language',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the language you want to practice',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(height: 16),

                if (_tensesLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading available tenses...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                ...Language.values.map((lang) {
                  final enabled = _isTenseAvailable(lang);
                  final name = lang.name[0].toUpperCase() + lang.name.substring(1);
                  final flag = _languageIcons[lang] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LanguageCard(
                      name: name,
                      flag: flag,
                      enabled: enabled,
                      loading: _tensesLoading,
                      tenseName: _selectedTense.displayName,
                      onTap: enabled ? () => _navigateToPractice(context, lang) : null,
                    ),
                  );
                }),

                const SizedBox(height: 16),

                Text(
                  'Practice tense',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which tense to practice',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<VerbTense>(
                    value: _selectedTense,
                    decoration: const InputDecoration(
                      labelText: 'Tense',
                      border: InputBorder.none,
                    ),
                    items: VerbTense.values.map((tense) {
                      return DropdownMenuItem(
                        value: tense,
                        child: Text(tense.displayName),
                      );
                    }).toList(),
                    onChanged: (VerbTense? value) {
                      if (value != null) {
                        setState(() => _selectedTense = value);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 32),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.bar_chart_rounded, size: 20),
                  label: const Text('View Progress'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Welcome to Verbae!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a language, choose a tense, and practice verb conjugations. '
              'Track your progress anytime on the dashboard.',
              style: TextStyle(
                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _dismissWelcome,
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPractice(BuildContext context, Language language) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeScreen(
          language: language,
          tense: _selectedTense,
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String name;
  final String flag;
  final bool enabled;
  final bool loading;
  final String tenseName;
  final VoidCallback? onTap;

  const _LanguageCard({
    required this.name,
    required this.flag,
    required this.enabled,
    required this.loading,
    required this.tenseName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String tooltipMessage;
    if (loading) {
      tooltipMessage = 'Loading available tenses...';
    } else if (!enabled) {
      tooltipMessage = 'No $tenseName verbs available for $name';
    } else {
      tooltipMessage = '';
    }

    final card = Material(
      color: enabled
          ? cs.primaryContainer
          : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: enabled ? cs.onPrimaryContainer : cs.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (enabled)
                      Text(
                        '$tenseName verbs available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
                    if (!enabled && !loading)
                      Text(
                        'No $tenseName verbs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.primary,
                )
              else if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltipMessage.isEmpty) return card;
    return Tooltip(message: tooltipMessage, child: card);
  }
}
