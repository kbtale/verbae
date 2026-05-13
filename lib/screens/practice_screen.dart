import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../models/verb.dart';
import '../services/verb_service.dart';
import '../services/stats_service.dart';

class PracticeScreen extends StatefulWidget {
  final Language language;
  final VerbTense tense;
  final VerbCategory? category;
  final VerbService? verbService;

  const PracticeScreen({
    super.key, 
    required this.language,
    required this.tense,
    this.category,
    this.verbService,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool?> _validationStatus = {};
  StatsService? _statsService;
  bool _statsReady = false;
  late final AnimationController _animationController;
  late final VerbService _verbService;
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
    _verbService = widget.verbService ?? VerbService();
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
    if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _verbSet = verbs;
        _currentVerbIndex = 0;
        _loadErrorMessage = null;
        _isLoading = false;
        _resetControllers();
      });
    } catch (error) {
      if (!mounted) return;
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
    if (_verbSet.isEmpty || _currentVerbIndex >= _verbSet.length) return;
    if (_answersLocked) return;

    final currentVerb = _verbSet[_currentVerbIndex];
    final conjugations = currentVerb.tenses[widget.tense] ?? {};
    bool allCorrect = true;

    conjugations.forEach((person, correctAnswer) {
      final userInput = _controllers[person]?.text.trim();
      bool isCorrect = userInput?.toLowerCase() == correctAnswer.toLowerCase();
      _validationStatus[person] = isCorrect;
      if (!isCorrect) allCorrect = false;
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
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    }

    final now = DateTime.now();
    final practiceTimeSeconds = _practiceStartTime != null
        ? now.difference(_practiceStartTime!).inSeconds
        : 0;

    _sessionTotal++;
    if (allCorrect) _sessionCorrect++;

    if (_statsReady) {
      await _statsService!.recordPractice(
        language: widget.language,
        tense: widget.tense,
        isCorrect: allCorrect,
        verbId: currentVerb.id,
        practiceTimeSeconds: practiceTimeSeconds,
      );
    }

    if (!mounted) return;

    setState(() {
      _answersLocked = true;
      if (!_masterMode || allCorrect) {
        _showCorrectAnswers = true;
      }
      if (allCorrect) _isAdvancing = true;
    });

    if (allCorrect) {
      _animationController.forward().then((_) {
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _nextVerb();
        });
      });
    }

    _practiceStartTime = DateTime.now();
  }

  void _nextVerb() {
    if (_verbSet.isEmpty) return;
    if (_isAdvancing) _isAdvancing = false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (_currentVerbIndex >= _verbSet.length - 1) {
      final totalTime = DateTime.now().difference(_sessionStartTime).inMinutes;
      final cs = Theme.of(context).colorScheme;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Practice Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, size: 48, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                'You got $_sessionCorrect out of $_sessionTotal correct',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Practice time: $totalTime min',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Return to Home'),
            ),
            FilledButton(
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

  InputDecoration _getInputDecoration(String key, ColorScheme cs) {
    final status = _validationStatus[key];
    final currentVerb = _verbSet[_currentVerbIndex];
    final correctAnswer = currentVerb.tenses[widget.tense]?[key] ?? '';

    Color borderColor;
    if (status == null) {
      borderColor = cs.outline;
    } else if (status == true) {
      borderColor = AppColors.stormyTeal;
    } else {
      borderColor = cs.error;
    }

    return InputDecoration(
      labelText: key,
      hintText: 'Enter $key conjugation',
      helperText: _showCorrectAnswers && status == false ? 'Correct: $correctAnswer' : null,
      helperStyle: TextStyle(color: cs.error),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
    );
  }

  Widget _buildNextButton(ColorScheme cs) {
    if (_masterMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Master Mode auto-advances after a correct answer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cs.tertiary,
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: _showCorrectAnswers && !_isAdvancing ? _nextVerb : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Next Verb'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.tense.displayName),
          scrolledUnderElevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadErrorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.tense.displayName),
          scrolledUnderElevation: 1,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text(_loadErrorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
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
          title: Text(widget.tense.displayName),
          scrolledUnderElevation: 1,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No verbs are available for ${widget.tense.displayName} in this language.',
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different tense.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentVerb = _verbSet[_currentVerbIndex];
    final conjugations = currentVerb.tenses[widget.tense] ?? {};
    final progress = (_currentVerbIndex + 1) / _verbSet.length;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          if (!context.mounted) return;
          setState(() => _canPop = true);
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tense.displayName),
          scrolledUnderElevation: 1,
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Master', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
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
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerLow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentVerb.infinitive,
                                      style: tt.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentVerbIndex + 1}/${_verbSet.length}',
                                      style: tt.labelMedium?.copyWith(
                                        color: cs.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_currentVerbIndex == 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Type the conjugation below and tap Check Answers',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ...conjugations.entries.map((entry) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: _controllers[entry.key],
                            decoration: _getInputDecoration(entry.key, cs),
                            textCapitalization: TextCapitalization.none,
                            onChanged: (_) {
                              setState(() {
                                _validationStatus[entry.key] = null;
                                _showCorrectAnswers = false;
                                _answersLocked = false;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      FilledButton(
                        onPressed: _statsReady ? _checkAnswer : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Check Answers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),

                      if (_masterMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Master Mode: All answers must be correct to proceed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.tertiary,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      _buildNextButton(cs),

                      const SizedBox(height: 8),

                      Center(
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.elasticOut,
                          ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.stormyTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Correct!',
                                style: tt.titleMedium?.copyWith(
                                  color: AppColors.stormyTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
