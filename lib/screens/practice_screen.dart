import 'package:flutter/material.dart';
import '../models/verb.dart';
import '../services/verb_service.dart';
import '../services/stats_service.dart';

class PracticeScreen extends StatefulWidget {
  final Language language;
  final VerbTense tense;
  final VerbCategory? category;

  const PracticeScreen({
    Key? key, 
    required this.language,
    required this.tense,
    this.category,
  }) : super(key: key);

  @override
  _PracticeScreenState createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool?> _validationStatus = {};
  late StatsService _statsService;
  late AnimationController _animationController;
  final VerbService _verbService = VerbService();
  List<Verb> _verbSet = [];
  int _currentVerbIndex = 0;
  bool _showCorrectAnswers = false;
  bool _masterMode = false;
  DateTime? _practiceStartTime;

  @override
  void initState() {
    super.initState();
    _loadVerbSet();
    _initializeStatsService();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _practiceStartTime = DateTime.now();
  }

  Future<void> _initializeStatsService() async {
    _statsService = await StatsService.create();
  }

  Future<void> _loadVerbSet() async {
    final verbs = await _verbService.generatePracticeSet(
      language: widget.language,
      category: widget.category,
    );
    
    setState(() {
      _verbSet = verbs.where((v) => v.hasTense(widget.tense)).toList();
      _resetControllers();
    });
  }

  void _resetControllers() {
    _controllers.clear();
    _validationStatus.clear();
    _showCorrectAnswers = false;
    if (_verbSet.isNotEmpty) {
      final currentVerb = _verbSet[_currentVerbIndex];
      final conjugations = currentVerb.tenses[widget.tense] ?? {};
      
      for (var person in conjugations.keys) {
        _controllers[person] = TextEditingController();
        _validationStatus[person] = null;
      }
    }
  }

  void _checkAnswer() async {
    final currentVerb = _verbSet[_currentVerbIndex];
    final conjugations = currentVerb.tenses[widget.tense] ?? {};
    bool allCorrect = true;

    conjugations.forEach((person, correctAnswer) {
      final userInput = _controllers[person]?.text.trim();
      bool isCorrect = userInput?.toLowerCase() == correctAnswer.toLowerCase();
      _validationStatus[person] = isCorrect;
      if (!isCorrect) {
        allCorrect = false;
      }
    });

    // Calculate practice time
    final now = DateTime.now();
    final practiceTimeSeconds = _practiceStartTime != null
        ? now.difference(_practiceStartTime!).inSeconds
        : 0;

    // Record practice results
    await _statsService.recordPractice(
      language: widget.language,
      tense: widget.tense,
      isCorrect: allCorrect,
      verbId: currentVerb.id,
      practiceTimeSeconds: practiceTimeSeconds,
    );

    setState(() {
      if (!_masterMode || allCorrect) {
        _showCorrectAnswers = true;
      }
    });

    if (allCorrect) {
      _animationController.forward().then((_) {
        _animationController.reverse();
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            _nextVerb();
          }
        });
      });
    }

    // Reset practice start time for next verb
    _practiceStartTime = DateTime.now();
  }

  void _nextVerb() {
    if (_currentVerbIndex >= _verbSet.length - 1) {
      // If we're at the last verb, show a completion dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Practice Complete!'),
          content: Text('You\'ve completed this practice set.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to home screen
              },
              child: Text('Return to Home'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentVerbIndex = 0;
                  _resetControllers();
                });
              },
              child: Text('Practice Again'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _currentVerbIndex++;
        _resetControllers();
      });
    }
  }

  void _moveToNextVerb() {
    if (_masterMode) {
      bool allCorrect = _validationStatus.values.every((status) => status == true);
      if (!allCorrect) return;
    }

    setState(() {
      _currentVerbIndex = (_currentVerbIndex + 1) % _verbSet.length;
      _resetControllers();
    });
  }

  InputDecoration _getInputDecoration(String key) {
    final status = _validationStatus[key];
    final currentVerb = _verbSet[_currentVerbIndex];
    final correctAnswer = currentVerb.tenses[widget.tense]?[key] ?? '';

    return InputDecoration(
      labelText: key,
      hintText: 'Enter ${key} conjugation',
      helperText: _showCorrectAnswers && status == false ? 'Correct: $correctAnswer' : null,
      helperStyle: TextStyle(color: Colors.red),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: status == null 
            ? Colors.grey 
            : status 
              ? Colors.green 
              : Colors.red,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: status == null 
            ? Colors.blue 
            : status 
              ? Colors.green 
              : Colors.red,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _showCorrectAnswers ? _nextVerb : null,
      child: Text('Next Verb'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_verbSet.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice ${widget.tense.getDisplayNameForLanguage(widget.language)}'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentVerb = _verbSet[_currentVerbIndex];
    final conjugations = currentVerb.tenses[widget.tense] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice ${widget.tense.getDisplayNameForLanguage(widget.language)}'),
        actions: [
          Row(
            children: [
              Text('Master Mode'),
              Switch(
                value: _masterMode,
                onChanged: (bool value) {
                  setState(() {
                    _masterMode = value;
                    _showCorrectAnswers = false;
                    _validationStatus.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Infinitive: ${currentVerb.infinitive}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            ...conjugations.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _controllers[entry.key],
                  decoration: _getInputDecoration(entry.key),
                  onChanged: (_) {
                    setState(() {
                      _validationStatus[entry.key] = null;
                      _showCorrectAnswers = false;
                    });
                  },
                ),
              )
            ).toList(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAnswer,
              child: Text('Check Answers'),
            ),
            if (_masterMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Master Mode: All answers must be correct to proceed',
                  style: TextStyle(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            _buildNextButton(),
            // Success animation
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _animationController,
                curve: Curves.elasticOut,
              ),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Correct!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }
}
