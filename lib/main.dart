import 'package:flutter/material.dart';
import 'screens/practice_screen.dart';
import 'screens/dashboard_screen.dart';
import 'models/verb.dart';
import 'services/verb_service.dart';

void main() {
  runApp(VerbaeApp());
}

class VerbaeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verbae',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.amber,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.indigo[900],
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.indigo[700],
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VerbTense _selectedTense = VerbTense.presentSimple;
  final VerbService _verbService = VerbService();
  Map<Language, Set<VerbTense>> _availableTenses = {};

  @override
  void initState() {
    super.initState();
    _loadAvailableTenses();
  }

  Future<void> _loadAvailableTenses() async {
    for (var language in Language.values) {
      final verbs = await _verbService.fetchVerbs(language);
      Set<VerbTense> tenses = {};
      for (var verb in verbs) {
        tenses.addAll(verb.tenses.keys);
      }
      setState(() {
        _availableTenses[language] = tenses;
      });
    }
  }

  bool _isTenseAvailable(Language language) {
    return _availableTenses[language]?.contains(_selectedTense) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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

                // Language buttons
                _buildLanguageButton(
                  context, 
                  'Italian', 
                  () => _navigateToPractice(context, Language.italian),
                  _isTenseAvailable(Language.italian),
                ),
                SizedBox(height: 12),
                _buildLanguageButton(
                  context, 
                  'English', 
                  () => _navigateToPractice(context, Language.english),
                  _isTenseAvailable(Language.english),
                ),
                SizedBox(height: 12),
                _buildLanguageButton(
                  context, 
                  'Spanish', 
                  () => _navigateToPractice(context, Language.spanish),
                  _isTenseAvailable(Language.spanish),
                ),
                SizedBox(height: 24),
                
                // Tense selector
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: DropdownButtonFormField<VerbTense>(
                    value: _selectedTense,
                    decoration: InputDecoration(
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
                SizedBox(height: 24),
                
                // Dashboard button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => DashboardScreen())
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Progress',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              ],
            ),
          ),
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
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 20),
          backgroundColor: enabled ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          foregroundColor: Colors.white,
          elevation: enabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          language, 
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
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
        )
      )
    );
  }
}
