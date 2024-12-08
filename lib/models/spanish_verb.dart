import 'package:flutter/foundation.dart';

enum SpanishVerbEnding {
  ar,
  er,
  ir,
}

enum SpanishTense {
  presentSimple,
  preterite,
  futureSimple,
  presentContinuous,
  imperfectContinuous,
  futureContinuous,
  presentPerfect,
  pluperfect,
  futurePerfect,
  presentPerfectContinuous,
  pluperfectContinuous,
  futurePerfectContinuous,
}

enum SpanishPronoun {
  yo,
  tu,
  elEllaUsted,
  nosotros,
  vosotros,
  ellosEllasUstedes,
}

class SpanishVerb {
  final String infinitive;
  final SpanishVerbEnding ending;
  final bool isRegular;
  final Map<String, String>? irregularForms;

  SpanishVerb({
    required this.infinitive,
    required this.ending,
    this.isRegular = true,
    this.irregularForms,
  });

  String get root => infinitive.substring(0, infinitive.length - 2);

  String conjugate({
    required SpanishTense tense,
    required SpanishPronoun pronoun,
    bool negative = false,
  }) {
    if (!isRegular && irregularForms != null) {
      String? irregularForm = _getIrregularForm(tense, pronoun);
      if (irregularForm != null) return _addNegation(irregularForm, negative);
    }

    switch (tense) {
      case SpanishTense.presentSimple:
        return _addNegation(_conjugatePresentSimple(pronoun), negative);
      case SpanishTense.preterite:
        return _addNegation(_conjugatePreterite(pronoun), negative);
      case SpanishTense.futureSimple:
        return _addNegation(_conjugateFutureSimple(pronoun), negative);
      case SpanishTense.presentContinuous:
        return _addNegation(_conjugatePresentContinuous(pronoun), negative);
      case SpanishTense.imperfectContinuous:
        return _addNegation(_conjugateImperfectContinuous(pronoun), negative);
      case SpanishTense.futureContinuous:
        return _addNegation(_conjugateFutureContinuous(pronoun), negative);
      case SpanishTense.presentPerfect:
        return _addNegation(_conjugatePresentPerfect(pronoun), negative);
      case SpanishTense.pluperfect:
        return _addNegation(_conjugatePluperfect(pronoun), negative);
      case SpanishTense.futurePerfect:
        return _addNegation(_conjugateFuturePerfect(pronoun), negative);
      case SpanishTense.presentPerfectContinuous:
        return _addNegation(_conjugatePresentPerfectContinuous(pronoun), negative);
      case SpanishTense.pluperfectContinuous:
        return _addNegation(_conjugatePluperfectContinuous(pronoun), negative);
      case SpanishTense.futurePerfectContinuous:
        return _addNegation(_conjugateFuturePerfectContinuous(pronoun), negative);
    }
  }

  String _conjugatePresentSimple(SpanishPronoun pronoun) {
    switch (ending) {
      case SpanishVerbEnding.ar:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return '${root}o';
          case SpanishPronoun.tu:
            return '${root}as';
          case SpanishPronoun.elEllaUsted:
            return '${root}a';
          case SpanishPronoun.nosotros:
            return '${root}amos';
          case SpanishPronoun.vosotros:
            return '${root}áis';
          case SpanishPronoun.ellosEllasUstedes:
            return '${root}an';
        }
      case SpanishVerbEnding.er:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return '${root}o';
          case SpanishPronoun.tu:
            return '${root}es';
          case SpanishPronoun.elEllaUsted:
            return '${root}e';
          case SpanishPronoun.nosotros:
            return '${root}emos';
          case SpanishPronoun.vosotros:
            return '${root}éis';
          case SpanishPronoun.ellosEllasUstedes:
            return '${root}en';
        }
      case SpanishVerbEnding.ir:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return '${root}o';
          case SpanishPronoun.tu:
            return '${root}es';
          case SpanishPronoun.elEllaUsted:
            return '${root}e';
          case SpanishPronoun.nosotros:
            return '${root}imos';
          case SpanishPronoun.vosotros:
            return '${root}ís';
          case SpanishPronoun.ellosEllasUstedes:
            return '${root}en';
        }
    }
  }

  String _conjugatePreterite(SpanishPronoun pronoun) {
    switch (ending) {
      case SpanishVerbEnding.ar:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return '${root}é';
          case SpanishPronoun.tu:
            return '${root}aste';
          case SpanishPronoun.elEllaUsted:
            return '${root}ó';
          case SpanishPronoun.nosotros:
            return '${root}amos';
          case SpanishPronoun.vosotros:
            return '${root}asteis';
          case SpanishPronoun.ellosEllasUstedes:
            return '${root}aron';
        }
      case SpanishVerbEnding.er:
      case SpanishVerbEnding.ir:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return '${root}í';
          case SpanishPronoun.tu:
            return '${root}iste';
          case SpanishPronoun.elEllaUsted:
            return '${root}ió';
          case SpanishPronoun.nosotros:
            return '${root}imos';
          case SpanishPronoun.vosotros:
            return '${root}isteis';
          case SpanishPronoun.ellosEllasUstedes:
            return '${root}ieron';
        }
    }
  }

  String _conjugateFutureSimple(SpanishPronoun pronoun) {
    // Future tense uses the infinitive as base
    switch (pronoun) {
      case SpanishPronoun.yo:
        return '${infinitive}é';
      case SpanishPronoun.tu:
        return '${infinitive}ás';
      case SpanishPronoun.elEllaUsted:
        return '${infinitive}á';
      case SpanishPronoun.nosotros:
        return '${infinitive}emos';
      case SpanishPronoun.vosotros:
        return '${infinitive}éis';
      case SpanishPronoun.ellosEllasUstedes:
        return '${infinitive}án';
    }
  }

  String _getGerund() {
    switch (ending) {
      case SpanishVerbEnding.ar:
        return '${root}ando';
      case SpanishVerbEnding.er:
      case SpanishVerbEnding.ir:
        return '${root}iendo';
    }
  }

  String _getParticiple() {
    switch (ending) {
      case SpanishVerbEnding.ar:
        return '${root}ado';
      case SpanishVerbEnding.er:
      case SpanishVerbEnding.ir:
        return '${root}ido';
    }
  }

  String _conjugateEstar(SpanishPronoun pronoun, SpanishTense tense) {
    // This is a simplified version. In a real implementation, we would use a proper irregular verb conjugation
    switch (tense) {
      case SpanishTense.presentSimple:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return 'estoy';
          case SpanishPronoun.tu:
            return 'estás';
          case SpanishPronoun.elEllaUsted:
            return 'está';
          case SpanishPronoun.nosotros:
            return 'estamos';
          case SpanishPronoun.vosotros:
            return 'estáis';
          case SpanishPronoun.ellosEllasUstedes:
            return 'están';
        }
      // Add other tenses as needed
      default:
        return 'estar'; // Placeholder
    }
  }

  String _conjugateHaber(SpanishPronoun pronoun, SpanishTense tense) {
    // This is a simplified version. In a real implementation, we would use a proper irregular verb conjugation
    switch (tense) {
      case SpanishTense.presentSimple:
        switch (pronoun) {
          case SpanishPronoun.yo:
            return 'he';
          case SpanishPronoun.tu:
            return 'has';
          case SpanishPronoun.elEllaUsted:
            return 'ha';
          case SpanishPronoun.nosotros:
            return 'hemos';
          case SpanishPronoun.vosotros:
            return 'habéis';
          case SpanishPronoun.ellosEllasUstedes:
            return 'han';
        }
      // Add other tenses as needed
      default:
        return 'haber'; // Placeholder
    }
  }

  String _conjugatePresentContinuous(SpanishPronoun pronoun) {
    return '${_conjugateEstar(pronoun, SpanishTense.presentSimple)} ${_getGerund()}';
  }

  String _conjugateImperfectContinuous(SpanishPronoun pronoun) {
    // Simplified. Would need proper imperfect estar conjugation
    return 'estaba ${_getGerund()}';
  }

  String _conjugateFutureContinuous(SpanishPronoun pronoun) {
    // Simplified. Would need proper future estar conjugation
    return 'estaré ${_getGerund()}';
  }

  String _conjugatePresentPerfect(SpanishPronoun pronoun) {
    return '${_conjugateHaber(pronoun, SpanishTense.presentSimple)} ${_getParticiple()}';
  }

  String _conjugatePluperfect(SpanishPronoun pronoun) {
    // Simplified. Would need proper imperfect haber conjugation
    return 'había ${_getParticiple()}';
  }

  String _conjugateFuturePerfect(SpanishPronoun pronoun) {
    // Simplified. Would need proper future haber conjugation
    return 'habré ${_getParticiple()}';
  }

  String _conjugatePresentPerfectContinuous(SpanishPronoun pronoun) {
    return '${_conjugateHaber(pronoun, SpanishTense.presentSimple)} estado ${_getGerund()}';
  }

  String _conjugatePluperfectContinuous(SpanishPronoun pronoun) {
    // Simplified. Would need proper imperfect haber conjugation
    return 'había estado ${_getGerund()}';
  }

  String _conjugateFuturePerfectContinuous(SpanishPronoun pronoun) {
    // Simplified. Would need proper future haber conjugation
    return 'habré estado ${_getGerund()}';
  }

  String? _getIrregularForm(SpanishTense tense, SpanishPronoun pronoun) {
    if (irregularForms == null) return null;
    String key = '${tense.name}_${pronoun.name}';
    return irregularForms![key];
  }

  String _addNegation(String verb, bool negative) {
    return negative ? 'no $verb' : verb;
  }

  factory SpanishVerb.regular(String infinitive) {
    SpanishVerbEnding ending;
    if (infinitive.endsWith('ar')) {
      ending = SpanishVerbEnding.ar;
    } else if (infinitive.endsWith('er')) {
      ending = SpanishVerbEnding.er;
    } else if (infinitive.endsWith('ir')) {
      ending = SpanishVerbEnding.ir;
    } else {
      throw ArgumentError('Invalid Spanish verb infinitive: $infinitive');
    }

    return SpanishVerb(
      infinitive: infinitive,
      ending: ending,
      isRegular: true,
    );
  }

  factory SpanishVerb.irregular(
    String infinitive,
    Map<String, String> irregularForms,
  ) {
    SpanishVerbEnding ending;
    if (infinitive.endsWith('ar')) {
      ending = SpanishVerbEnding.ar;
    } else if (infinitive.endsWith('er')) {
      ending = SpanishVerbEnding.er;
    } else if (infinitive.endsWith('ir')) {
      ending = SpanishVerbEnding.ir;
    } else {
      throw ArgumentError('Invalid Spanish verb infinitive: $infinitive');
    }

    return SpanishVerb(
      infinitive: infinitive,
      ending: ending,
      isRegular: false,
      irregularForms: irregularForms,
    );
  }
}
