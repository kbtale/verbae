// Verb model to represent verbs across languages
class Verb {
  final String id;
  final String base;
  final String language;
  final String category;
  final bool isRegular;
  final Map<String, dynamic> conjugationRules;
  final Map<String, dynamic> spellingRules;
  final Map<String, dynamic>? irregularForms;

  Verb({
    required this.id,
    required this.base,
    required this.language,
    required this.category,
    required this.isRegular,
    required this.conjugationRules,
    required this.spellingRules,
    this.irregularForms,
  });

  String conjugate({
    required VerbTense tense,
    required String subject,
    required VerbForm form,
  }) {
    if (!isRegular && irregularForms != null) {
      return _conjugateIrregular(tense, subject, form);
    }
    return _conjugateRegular(tense, subject, form);
  }

  String _conjugateRegular(VerbTense tense, String subject, VerbForm form) {
    final tenseStr = _getTenseString(tense);
    final formStr = _getFormString(form);
    
    var template = conjugationRules[tenseStr][formStr][subject];
    return _applyTemplate(template, base);
  }

  String _conjugateIrregular(VerbTense tense, String subject, VerbForm form) {
    final tenseStr = _getTenseString(tense);
    final formStr = _getFormString(form);
    
    return irregularForms![tenseStr][formStr][subject];
  }

  String _applyTemplate(String template, String baseVerb) {
    var processedBase = _applySpellingRules(baseVerb, template);
    return template.replaceAll('{base}', processedBase);
  }

  String _applySpellingRules(String word, String template) {
    if (template.contains('{base}s')) {
      return _applyThirdPersonRule(word);
    } else if (template.contains('{base}ed')) {
      return _applyPastTenseRule(word);
    } else if (template.contains('{base}ing')) {
      return _applyIngFormRule(word);
    }
    return word;
  }

  String _applyThirdPersonRule(String word) {
    // Rule 1: verbs ending in s, sh, ch, x, z, o add 'es'
    if (word.endsWith('s') || 
        word.endsWith('sh') || 
        word.endsWith('ch') || 
        word.endsWith('x') || 
        word.endsWith('z') || 
        word.endsWith('o')) {
      return '${word}es';
    }
    
    // Rule 2: consonant + y -> ies
    if (word.endsWith('y') && word.length > 1) {
      String beforeY = word[word.length - 2];
      if (!_isVowel(beforeY)) {
        return '${word.substring(0, word.length - 1)}ies';
      }
    }
    
    // Default: just add 's'
    return '${word}s';
  }

  String _applyPastTenseRule(String word) {
    // Rule 1: verbs ending in e just add 'd'
    if (word.endsWith('e')) {
      return '${word}d';
    }
    
    // Rule 2: consonant + y -> ied
    if (word.endsWith('y') && word.length > 1) {
      String beforeY = word[word.length - 2];
      if (!_isVowel(beforeY)) {
        return '${word.substring(0, word.length - 1)}ied';
      }
    }
    
    // Rule 3: CVC pattern (Consonant-Vowel-Consonant) -> double final consonant
    if (_isCVCPattern(word)) {
      return '${word}${word[word.length - 1]}ed';
    }
    
    // Default: just add 'ed'
    return '${word}ed';
  }

  String _applyIngFormRule(String word) {
    // Rule 1: verbs ending in 'ie' -> 'y' + ing
    if (word.endsWith('ie')) {
      return '${word.substring(0, word.length - 2)}ying';
    }
    
    // Rule 2: verbs ending in 'e' drop the 'e' and add 'ing'
    if (word.endsWith('e')) {
      return '${word.substring(0, word.length - 1)}ing';
    }
    
    // Rule 3: CVC pattern -> double final consonant
    if (_isCVCPattern(word)) {
      return '${word}${word[word.length - 1]}ing';
    }
    
    // Default: just add 'ing'
    return '${word}ing';
  }

  bool _isVowel(String char) {
    return 'aeiou'.contains(char.toLowerCase());
  }

  bool _isCVCPattern(String word) {
    if (word.length < 3) return false;
    
    // Get last three characters
    String last = word[word.length - 1];
    String middle = word[word.length - 2];
    String beforeMiddle = word[word.length - 3];
    
    // Check if it follows Consonant-Vowel-Consonant pattern
    // and the word is stressed on the last syllable
    return !_isVowel(last) &&  // Last letter is consonant
           _isVowel(middle) &&  // Middle letter is vowel
           !_isVowel(beforeMiddle) && // Letter before middle is consonant
           !_isStressExempt(word); // Word is not stress-exempt
  }

  bool _isStressExempt(String word) {
    // Words ending in w, x, y are exempt from doubling
    return word.endsWith('w') || 
           word.endsWith('x') || 
           word.endsWith('y');
  }

  String _getTenseString(VerbTense tense) {
    switch (tense) {
      case VerbTense.presentSimple:
        return 'present_simple';
      case VerbTense.presentContinuous:
        return 'present_continuous';
      case VerbTense.pastSimple:
        return 'past_simple';
      case VerbTense.pastContinuous:
        return 'past_continuous';
      case VerbTense.futureSimple:
        return 'future_simple';
      case VerbTense.futureContinuous:
        return 'future_continuous';
    }
  }

  String _getFormString(VerbForm form) {
    switch (form) {
      case VerbForm.affirmative:
        return 'affirmative';
      case VerbForm.negative:
        return 'negative';
      case VerbForm.question:
        return 'question';
    }
  }

  factory Verb.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'regular') {
      return Verb(
        id: '${json['base']}_1',
        base: json['base'],
        language: json['language'],
        category: json['category'],
        isRegular: true,
        conjugationRules: json['conjugation_rules'],
        spellingRules: json['spelling_rules'],
      );
    } else {
      return Verb(
        id: json['base'],
        base: json['base'],
        language: json['language'],
        category: json['category'],
        isRegular: false,
        conjugationRules: {},
        spellingRules: {},
        irregularForms: json['forms'],
      );
    }
  }
}

// Enum for verb categories
enum VerbCategory {
  regular,
  irregular,
  reflexive,
  modal
}

// Enum for languages
enum Language {
  italian,
  english,
  spanish
}

// Enum for verb tenses
enum VerbTense {
  presentSimple,
  presentContinuous,
  pastSimple,
  pastContinuous,
  futureSimple,
  futureContinuous
}

// Enum for verb forms
enum VerbForm {
  affirmative,
  negative,
  question
}

class EnglishVerb {
  final String base;
  final String? pastSimple;
  final String? pastParticiple;
  final bool isRegular;

  EnglishVerb({
    required this.base,
    this.pastSimple,
    this.pastParticiple,
    this.isRegular = true,
  });

  String conjugate({
    required VerbTense tense,
    required String subject,
    required VerbForm form,
  }) {
    switch (tense) {
      case VerbTense.presentSimple:
        return _conjugatePresentSimple(subject, form);
      case VerbTense.presentContinuous:
        return _conjugatePresentContinuous(subject, form);
      case VerbTense.pastSimple:
        return _conjugatePastSimple(subject, form);
      case VerbTense.pastContinuous:
        return _conjugatePastContinuous(subject, form);
      case VerbTense.futureSimple:
        return _conjugateFutureSimple(subject, form);
      case VerbTense.futureContinuous:
        return _conjugateFutureContinuous(subject, form);
    }
  }

  String _conjugatePresentSimple(String subject, VerbForm form) {
    switch (form) {
      case VerbForm.affirmative:
        if (subject == 'he/she/it') {
          return _applyThirdPersonRule(base);
        }
        return base;
      
      case VerbForm.negative:
        if (subject == 'he/she/it') {
          return 'does not $base';
        }
        return 'do not $base';
      
      case VerbForm.question:
        if (subject == 'he/she/it') {
          return 'does $subject $base';
        }
        return 'do $subject $base';
    }
  }

  String _conjugatePresentContinuous(String subject, VerbForm form) {
    String auxiliary = _getBeAuxiliary(subject, false);
    String participle = _getPresentParticiple();

    switch (form) {
      case VerbForm.affirmative:
        return '$auxiliary $participle';
      case VerbForm.negative:
        return '$auxiliary not $participle';
      case VerbForm.question:
        return '${auxiliary.split(' ')[0]} $subject ${auxiliary.split(' ')[1] ?? ''} $participle';
    }
  }

  String _conjugatePastSimple(String subject, VerbForm form) {
    String pastForm = isRegular ? _applyPastTenseRule() : pastSimple!;

    switch (form) {
      case VerbForm.affirmative:
        return pastForm;
      case VerbForm.negative:
        return 'did not $base';
      case VerbForm.question:
        return 'did $subject $base';
    }
  }

  String _conjugatePastContinuous(String subject, VerbForm form) {
    String auxiliary = _getBeAuxiliary(subject, true);
    String participle = _getPresentParticiple();

    switch (form) {
      case VerbForm.affirmative:
        return '$auxiliary $participle';
      case VerbForm.negative:
        return '$auxiliary not $participle';
      case VerbForm.question:
        return '${auxiliary.split(' ')[0]} $subject ${auxiliary.split(' ')[1] ?? ''} $participle';
    }
  }

  String _conjugateFutureSimple(String subject, VerbForm form) {
    switch (form) {
      case VerbForm.affirmative:
        return 'will $base';
      case VerbForm.negative:
        return 'will not $base';
      case VerbForm.question:
        return 'will $subject $base';
    }
  }

  String _conjugateFutureContinuous(String subject, VerbForm form) {
    switch (form) {
      case VerbForm.affirmative:
        return 'will be ${_getPresentParticiple()}';
      case VerbForm.negative:
        return 'will not be ${_getPresentParticiple()}';
      case VerbForm.question:
        return 'will $subject be ${_getPresentParticiple()}';
    }
  }

  String _getBeAuxiliary(String subject, bool past) {
    if (past) {
      switch (subject) {
        case 'I':
        case 'he/she/it':
          return 'was';
        default:
          return 'were';
      }
    } else {
      switch (subject) {
        case 'I':
          return 'am';
        case 'he/she/it':
          return 'is';
        default:
          return 'are';
      }
    }
  }

  String _applyThirdPersonRule() {
    // Rule 1: verbs ending in s, sh, ch, x, z, o add 'es'
    if (base.endsWith('s') || 
        base.endsWith('sh') || 
        base.endsWith('ch') || 
        base.endsWith('x') || 
        base.endsWith('z') || 
        base.endsWith('o')) {
      return '${base}es';
    }
    
    // Rule 2: consonant + y -> ies
    if (base.endsWith('y') && base.length > 1) {
      String beforeY = base[base.length - 2];
      if (!_isVowel(beforeY)) {
        return '${base.substring(0, base.length - 1)}ies';
      }
    }
    
    // Default: just add 's'
    return '${base}s';
  }

  String _applyPastTenseRule() {
    // Rule 1: verbs ending in e just add 'd'
    if (base.endsWith('e')) {
      return '${base}d';
    }
    
    // Rule 2: consonant + y -> ied
    if (base.endsWith('y') && base.length > 1) {
      String beforeY = base[base.length - 2];
      if (!_isVowel(beforeY)) {
        return '${base.substring(0, base.length - 1)}ied';
      }
    }
    
    // Rule 3: CVC pattern -> double final consonant
    if (_isCVCPattern()) {
      return '${base}${base[base.length - 1]}ed';
    }
    
    // Default: just add 'ed'
    return '${base}ed';
  }

  String _getPresentParticiple() {
    // Rule 1: verbs ending in 'ie' -> 'y' + ing
    if (base.endsWith('ie')) {
      return '${base.substring(0, base.length - 2)}ying';
    }
    
    // Rule 2: verbs ending in 'e' drop the 'e' and add 'ing'
    if (base.endsWith('e')) {
      return '${base.substring(0, base.length - 1)}ing';
    }
    
    // Rule 3: CVC pattern -> double final consonant
    if (_isCVCPattern()) {
      return '${base}${base[base.length - 1]}ing';
    }
    
    // Default: just add 'ing'
    return '${base}ing';
  }

  bool _isVowel(String char) {
    return 'aeiou'.contains(char.toLowerCase());
  }

  bool _isCVCPattern() {
    if (base.length < 3) return false;
    
    // Get last three characters
    String last = base[base.length - 1];
    String middle = base[base.length - 2];
    String beforeMiddle = base[base.length - 3];
    
    // Check if it follows Consonant-Vowel-Consonant pattern
    return !_isVowel(last) &&  // Last letter is consonant
           _isVowel(middle) &&  // Middle letter is vowel
           !_isVowel(beforeMiddle) && // Letter before middle is consonant
           !_isStressExempt(); // Word is not stress-exempt
  }

  bool _isStressExempt() {
    // Words ending in w, x, y are exempt from doubling
    return base.endsWith('w') || 
           base.endsWith('x') || 
           base.endsWith('y');
  }

  factory EnglishVerb.regular(String base) {
    return EnglishVerb(
      base: base,
      isRegular: true,
    );
  }

  factory EnglishVerb.irregular(String base, String pastSimple, String pastParticiple) {
    return EnglishVerb(
      base: base,
      pastSimple: pastSimple,
      pastParticiple: pastParticiple,
      isRegular: false,
    );
  }
}
