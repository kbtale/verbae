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
      if (!mounted) {
        return;
      }
      setState(() {
        _availableTenses[language] = tenses;
      });
    }
    if (!mounted) return;
    setState(() => _tensesLoading = false);
  }

  bool _isTenseAvailable(Language language) {
    return _availableTenses[language]?.contains(_selectedTense) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verbae'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_showWelcomeCard) _buildWelcomeCard(context),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Image.asset(
                    'assets/images/verbae-high-resolution-logo-transparent.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                
                // Language selection text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Select a Language',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (_tensesLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Loading available tenses...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                // Language buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final languageButtons = <Widget>[
                      _buildLanguageButton(
                        context, 
                        'Italian', 
                        () => _navigateToPractice(context, Language.italian),
                        _isTenseAvailable(Language.italian),
                      ),
                      _buildLanguageButton(
                        context, 
                        'English', 
                        () => _navigateToPractice(context, Language.english),
                        _isTenseAvailable(Language.english),
                      ),
                      _buildLanguageButton(
                        context, 
                        'Spanish', 
                        () => _navigateToPractice(context, Language.spanish),
                        _isTenseAvailable(Language.spanish),
                      ),
                    ];

                    if (constraints.maxWidth > 720) {
                      return GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: languageButtons,
                      );
                    }
                    return Column(children: languageButtons);
                  },
                ),
                const SizedBox(height: 24),
                
                // Tense selector
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: DropdownButtonFormField<VerbTense>(
                    initialValue: _selectedTense,
                    decoration: const InputDecoration(
                      labelText: 'Select Tense',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: VerbTense.values.map((tense) {
                      return DropdownMenuItem(
                        value: tense,
                        child: Text(tense.displayName),
                      );
                    }).toList(),
                    onChanged: (VerbTense? value) {
                      if (value != null) {
                        setState(() {
                          _selectedTense = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Dashboard button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Progress',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Welcome to Verbae!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a language, choose a tense, and practice verb conjugations. Track your progress anytime with View Progress.',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _dismissWelcome,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, 
    String language, 
    VoidCallback onPressed,
    bool enabled,
  ) {
    final button = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: enabled ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          foregroundColor: Colors.white,
          elevation: enabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          language, 
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    if (!enabled && _tensesLoading) {
      return Tooltip(
        message: 'Loading available tenses...',
        child: button,
      );
    }
    if (!enabled) {
      return Tooltip(
        message: 'No verbs available for ${_selectedTense.displayName}',
        child: button,
      );
    }
    return button;
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
