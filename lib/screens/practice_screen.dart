import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/verb.dart';
import '../services/verb_service.dart';
import '../services/stats_service.dart';

class PracticeScreen extends StatefulWidget {
  final Language language;
  final VerbTense tense;
  final VerbCategory? category;

  const PracticeScreen({
    super.key, 
    required this.language,
    required this.tense,
    this.category,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool?> _validationStatus = {};
  StatsService? _statsService;
  bool _statsReady = false;
  late AnimationController _animationController;
  final VerbService _verbService = VerbService();
  List<Verb> _verbSet = [];
  int _currentVerbIndex = 0;
  bool _showCorrectAnswers = false;
  bool _masterMode = false;
  bool _answersLocked = false;
  bool _isAdvancing = false;
  int _sessionCorrect = 0;
  int _sessionTotal = 0;
  DateTime? _practiceStartTime;
  DateTime _sessionStartTime = DateTime.now();
  bool _canPop = false;
  bool _isLoading = true;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadVerbSet();
    _initializeStatsService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _practiceStartTime = DateTime.now();
  }

  Future<void> _initializeStatsService() async {
    final statsService = await StatsService.create();
    if (!mounted) {
      return;
    }
    _statsService = statsService;
    _statsReady = true;
  }

  Future<void> _loadVerbSet() async {
    try {
      final verbs = await _verbService.generatePracticeSet(
        language: widget.language,
        tense: widget.tense,
        category: widget.category?.name,
      );
      
      if (!mounted) {
        return;
      }

      setState(() {
        _verbSet = verbs;
        _currentVerbIndex = 0;
        _loadErrorMessage = null;
        _isLoading = false;
        _resetControllers();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _verbSet = [];
        _currentVerbIndex = 0;
        _loadErrorMessage = 'Unable to load practice set. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _resetControllers() {
    _disposeControllers();
    _controllers.clear();
    _validationStatus.clear();
    _showCorrectAnswers = false;
    _answersLocked = false;
    _isAdvancing = false;
    if (_verbSet.isNotEmpty && _currentVerbIndex < _verbSet.length) {
      final currentVerb = _verbSet[_currentVerbIndex];
      final conjugations = currentVerb.tenses[widget.tense] ?? {};
      
      for (var person in conjugations.keys) {
        _controllers[person] = TextEditingController();
        _validationStatus[person] = null;
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }

  void _checkAnswer() async {
    if (_verbSet.isEmpty || _currentVerbIndex >= _verbSet.length) {
      return;
    }

    if (_answersLocked) {
      return;
    }

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

    if (allCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
      final wrongFields = _validationStatus.entries
          .where((e) => e.value == false)
          .map((e) => e.key)
          .toList();
      if (wrongFields.isNotEmpty && mounted) {
        final correctValues = wrongFields.map((p) => '$p: ${conjugations[p]}').join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correct forms: $correctValues'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }

    // Calculate practice time
    final now = DateTime.now();
    final practiceTimeSeconds = _practiceStartTime != null
        ? now.difference(_practiceStartTime!).inSeconds
        : 0;

    _sessionTotal++;
    if (allCorrect) {
      _sessionCorrect++;
    }

    // Record practice results
    if (_statsReady) {
      await _statsService!.recordPractice(
        language: widget.language,
        tense: widget.tense,
        isCorrect: allCorrect,
        verbId: currentVerb.id,
        practiceTimeSeconds: practiceTimeSeconds,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _answersLocked = true;
      if (!_masterMode || allCorrect) {
        _showCorrectAnswers = true;
      }
      if (allCorrect) {
        _isAdvancing = true;
      }
    });

    if (allCorrect) {
      _animationController.forward().then((_) {
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 800), () {
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
    if (_verbSet.isEmpty) {
      return;
    }

    if (_isAdvancing) {
      _isAdvancing = false;
    }

    if (_currentVerbIndex >= _verbSet.length - 1) {
      final totalTime = DateTime.now().difference(_sessionStartTime).inMinutes;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Practice Complete!'),
          content: Text(
            'You got $_sessionCorrect out of $_sessionTotal correct.\n\nPractice time: $totalTime min',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to home screen
              },
              child: const Text('Return to Home'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentVerbIndex = 0;
                  _practiceStartTime = DateTime.now();
                  _sessionStartTime = DateTime.now();
                  _sessionCorrect = 0;
                  _sessionTotal = 0;
                  _resetControllers();
                });
              },
              child: const Text('Practice Again'),
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

  InputDecoration _getInputDecoration(String key) {
    final status = _validationStatus[key];
    final currentVerb = _verbSet[_currentVerbIndex];
    final correctAnswer = currentVerb.tenses[widget.tense]?[key] ?? '';

    return InputDecoration(
      labelText: key,
      hintText: 'Enter $key conjugation',
      helperText: _showCorrectAnswers && status == false ? 'Correct: $correctAnswer' : null,
      helperStyle: const TextStyle(color: Colors.red),
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
    if (_masterMode) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Master Mode auto-advances after a correct answer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _showCorrectAnswers && !_isAdvancing ? _nextVerb : null,
      child: const Text('Next Verb'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice ${widget.tense.getDisplayNameForLanguage(widget.language)}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadErrorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice ${widget.tense.getDisplayNameForLanguage(widget.language)}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadErrorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _loadErrorMessage = null;
                    });
                    _loadVerbSet();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_verbSet.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice ${widget.tense.getDisplayNameForLanguage(widget.language)}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No verbs are available for ${widget.tense.getDisplayNameForLanguage(widget.language)} in this language.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try Present Simple instead.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentVerb = _verbSet[_currentVerbIndex];
    final conjugations = currentVerb.tenses[widget.tense] ?? {};

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Practice?'),
            content: const Text('Your progress in this session will be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ?? false;
        if (shouldPop && mounted) {
          setState(() => _canPop = true);
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Practice ${widget.tense.getDisplayNameForLanguage(widget.language)}'),
        actions: [
          Row(
            children: [
              const Text('Master Mode'),
              Switch(
                value: _masterMode,
                onChanged: (bool value) {
                  setState(() {
                    _masterMode = value;
                    _showCorrectAnswers = false;
                    _answersLocked = false;
                    _isAdvancing = false;
                    _validationStatus.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Infinitive: ${currentVerb.infinitive}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Verb ${_currentVerbIndex + 1} of ${_verbSet.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            if (_currentVerbIndex == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Type the conjugation and tap Check Answers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
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
                      _answersLocked = false;
                    });
                  },
                ),
              )
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _statsReady ? _checkAnswer : null,
              child: const Text('Check Answers'),
            ),
            if (_masterMode)
              const Padding(
                padding: EdgeInsets.all(8.0),
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
                padding: const EdgeInsets.all(8),
                child: const Text(
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
      ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeControllers();
    _animationController.dispose();
    super.dispose();
  }
}
