import 'package:flutter/foundation.dart';

enum ItalianVerbEnding {
  are,
  ere,
  ire,
}

enum ItalianTense {
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

enum ItalianPronoun {
  io,
  tu,
  luiLei,
  noi,
  voi,
  loro,
}

class ItalianVerb {
  final String infinitive;
  final ItalianVerbEnding ending;
  final bool isRegular;
  final List<String>? irregularForms;
  final bool usesEssere;

  ItalianVerb({
    required this.infinitive,
    required this.ending,
    this.isRegular = true,
    this.irregularForms,
    this.usesEssere = false,
  });

  String get root => infinitive.substring(0, infinitive.length - 3);

  String conjugate({
    required ItalianTense tense,
    required ItalianPronoun pronoun,
    bool negative = false,
  }) {
    if (!isRegular && irregularForms != null) {
      String? irregularForm = _getIrregularForm(tense, pronoun);
      if (irregularForm != null) return _addNegation(irregularForm, negative);
    }

    switch (tense) {
      case ItalianTense.presentSimple:
        return _addNegation(_conjugatePresentSimple(pronoun), negative);
      case ItalianTense.preterite:
        return _addNegation(_conjugatePreterite(pronoun), negative);
      case ItalianTense.futureSimple:
        return _addNegation(_conjugateFutureSimple(pronoun), negative);
      case ItalianTense.presentContinuous:
        return _addNegation(_conjugatePresentContinuous(pronoun), negative);
      case ItalianTense.imperfectContinuous:
        return _addNegation(_conjugateImperfectContinuous(pronoun), negative);
      case ItalianTense.futureContinuous:
        return _addNegation(_conjugateFutureContinuous(pronoun), negative);
      case ItalianTense.presentPerfect:
        return _addNegation(_conjugatePresentPerfect(pronoun), negative);
      case ItalianTense.pluperfect:
        return _addNegation(_conjugatePluperfect(pronoun), negative);
      case ItalianTense.futurePerfect:
        return _addNegation(_conjugateFuturePerfect(pronoun), negative);
      case ItalianTense.presentPerfectContinuous:
        return _addNegation(_conjugatePresentPerfectContinuous(pronoun), negative);
      case ItalianTense.pluperfectContinuous:
        return _addNegation(_conjugatePluperfectContinuous(pronoun), negative);
      case ItalianTense.futurePerfectContinuous:
        return _addNegation(_conjugateFuturePerfectContinuous(pronoun), negative);
    }
  }

  String _conjugatePresentSimple(ItalianPronoun pronoun) {
    switch (ending) {
      case ItalianVerbEnding.are:
        switch (pronoun) {
          case ItalianPronoun.io:
            return '${root}o';
          case ItalianPronoun.tu:
            return '${root}i';
          case ItalianPronoun.luiLei:
            return '${root}a';
          case ItalianPronoun.noi:
            return '${root}iamo';
          case ItalianPronoun.voi:
            return '${root}ate';
          case ItalianPronoun.loro:
            return '${root}ano';
        }
      case ItalianVerbEnding.ere:
        switch (pronoun) {
          case ItalianPronoun.io:
            return '${root}o';
          case ItalianPronoun.tu:
            return '${root}i';
          case ItalianPronoun.luiLei:
            return '${root}e';
          case ItalianPronoun.noi:
            return '${root}iamo';
          case ItalianPronoun.voi:
            return '${root}ete';
          case ItalianPronoun.loro:
            return '${root}ono';
        }
      case ItalianVerbEnding.ire:
        switch (pronoun) {
          case ItalianPronoun.io:
            return '${root}o';
          case ItalianPronoun.tu:
            return '${root}i';
          case ItalianPronoun.luiLei:
            return '${root}e';
          case ItalianPronoun.noi:
            return '${root}iamo';
          case ItalianPronoun.voi:
            return '${root}ite';
          case ItalianPronoun.loro:
            return '${root}ono';
        }
    }
  }

  String _conjugateFutureSimple(ItalianPronoun pronoun) {
    String futureRoot = _getFutureRoot();
    switch (pronoun) {
      case ItalianPronoun.io:
        return '${futureRoot}ò';
      case ItalianPronoun.tu:
        return '${futureRoot}ai';
      case ItalianPronoun.luiLei:
        return '${futureRoot}à';
      case ItalianPronoun.noi:
        return '${futureRoot}emo';
      case ItalianPronoun.voi:
        return '${futureRoot}ete';
      case ItalianPronoun.loro:
        return '${futureRoot}anno';
    }
  }

  String _getFutureRoot() {
    switch (ending) {
      case ItalianVerbEnding.are:
        return '${root}er';
      case ItalianVerbEnding.ere:
        return '${root}er';
      case ItalianVerbEnding.ire:
        return '${root}ir';
    }
  }

  String _getGerund() {
    switch (ending) {
      case ItalianVerbEnding.are:
        return '${root}ando';
      case ItalianVerbEnding.ere:
      case ItalianVerbEnding.ire:
        return '${root}endo';
    }
  }

  String _getParticiple() {
    switch (ending) {
      case ItalianVerbEnding.are:
        return '${root}ato';
      case ItalianVerbEnding.ere:
        return '${root}uto';
      case ItalianVerbEnding.ire:
        return '${root}ito';
    }
  }

  String _conjugateStare(ItalianPronoun pronoun, ItalianTense tense) {
    // This is a simplified version. In a real implementation, we would use the irregular verb conjugation
    switch (tense) {
      case ItalianTense.presentSimple:
        switch (pronoun) {
          case ItalianPronoun.io:
            return 'sto';
          case ItalianPronoun.tu:
            return 'stai';
          case ItalianPronoun.luiLei:
            return 'sta';
          case ItalianPronoun.noi:
            return 'stiamo';
          case ItalianPronoun.voi:
            return 'state';
          case ItalianPronoun.loro:
            return 'stanno';
        }
      default:
        return 'stare'; // Placeholder
    }
  }

  String _conjugateAuxiliary(ItalianPronoun pronoun, ItalianTense tense) {
    String auxiliary = usesEssere ? 'essere' : 'avere';
    // This is a simplified version. In a real implementation, we would use the irregular verb conjugation
    if (auxiliary == 'avere') {
      switch (pronoun) {
        case ItalianPronoun.io:
          return 'ho';
        case ItalianPronoun.tu:
          return 'hai';
        case ItalianPronoun.luiLei:
          return 'ha';
        case ItalianPronoun.noi:
          return 'abbiamo';
        case ItalianPronoun.voi:
          return 'avete';
        case ItalianPronoun.loro:
          return 'hanno';
      }
    } else {
      switch (pronoun) {
        case ItalianPronoun.io:
          return 'sono';
        case ItalianPronoun.tu:
          return 'sei';
        case ItalianPronoun.luiLei:
          return 'è';
        case ItalianPronoun.noi:
          return 'siamo';
        case ItalianPronoun.voi:
          return 'siete';
        case ItalianPronoun.loro:
          return 'sono';
      }
    }
  }

  String _conjugatePreterite(ItalianPronoun pronoun) {
    return '${_conjugateAuxiliary(pronoun, ItalianTense.presentSimple)} ${_getParticiple()}';
  }

  String _conjugatePresentContinuous(ItalianPronoun pronoun) {
    return '${_conjugateStare(pronoun, ItalianTense.presentSimple)} ${_getGerund()}';
  }

  String _conjugateImperfectContinuous(ItalianPronoun pronoun) {
    // Simplified. Would need proper imperfect stare conjugation
    return 'stavo ${_getGerund()}';
  }

  String _conjugateFutureContinuous(ItalianPronoun pronoun) {
    // Simplified. Would need proper future stare conjugation
    return 'starò ${_getGerund()}';
  }

  String _conjugatePresentPerfect(ItalianPronoun pronoun) {
    return '${_conjugateAuxiliary(pronoun, ItalianTense.presentSimple)} ${_getParticiple()}';
  }

  String _conjugatePluperfect(ItalianPronoun pronoun) {
    // Simplified. Would need proper imperfect auxiliary conjugation
    String aux = usesEssere ? 'ero' : 'avevo';
    return '$aux ${_getParticiple()}';
  }

  String _conjugateFuturePerfect(ItalianPronoun pronoun) {
    // Simplified. Would need proper future auxiliary conjugation
    String aux = usesEssere ? 'sarò' : 'avrò';
    return '$aux ${_getParticiple()}';
  }

  String _conjugatePresentPerfectContinuous(ItalianPronoun pronoun) {
    return '${_conjugateAuxiliary(pronoun, ItalianTense.presentSimple)} stato ${_getGerund()}';
  }

  String _conjugatePluperfectContinuous(ItalianPronoun pronoun) {
    // Simplified. Would need proper imperfect auxiliary conjugation
    String aux = usesEssere ? 'ero' : 'avevo';
    return '$aux stato ${_getGerund()}';
  }

  String _conjugateFuturePerfectContinuous(ItalianPronoun pronoun) {
    // Simplified. Would need proper future auxiliary conjugation
    String aux = usesEssere ? 'sarò' : 'avrò';
    return '$aux stato ${_getGerund()}';
  }

  String? _getIrregularForm(ItalianTense tense, ItalianPronoun pronoun) {
    if (irregularForms == null) return null;
    
    // For irregular verbs, we store:
    // [0]: infinitive
    // [1-6]: present simple (io, tu, lui/lei, noi, voi, loro)
    // [7-12]: imperfect (io, tu, lui/lei, noi, voi, loro)
    // [13-18]: future simple (io, tu, lui/lei, noi, voi, loro)
    
    int index;
    switch (tense) {
      case ItalianTense.presentSimple:
        index = pronoun.index + 1;
        break;
      case ItalianTense.preterite:
        index = pronoun.index + 7;
        break;
      case ItalianTense.futureSimple:
        index = pronoun.index + 13;
        break;
      default:
        return null;
    }
    
    return index < irregularForms!.length ? irregularForms![index] : null;
  }

  String _addNegation(String verb, bool negative) {
    return negative ? 'non $verb' : verb;
  }

  factory ItalianVerb.regular(String infinitive) {
    ItalianVerbEnding ending;
    if (infinitive.endsWith('are')) {
      ending = ItalianVerbEnding.are;
    } else if (infinitive.endsWith('ere')) {
      ending = ItalianVerbEnding.ere;
    } else if (infinitive.endsWith('ire')) {
      ending = ItalianVerbEnding.ire;
    } else {
      throw ArgumentError('Invalid Italian verb infinitive: $infinitive');
    }

    return ItalianVerb(
      infinitive: infinitive,
      ending: ending,
      isRegular: true,
    );
  }

  factory ItalianVerb.irregular(
    String infinitive,
    List<String> irregularForms, {
    bool usesEssere = false,
  }) {
    ItalianVerbEnding ending;
    if (infinitive.endsWith('are')) {
      ending = ItalianVerbEnding.are;
    } else if (infinitive.endsWith('ere')) {
      ending = ItalianVerbEnding.ere;
    } else if (infinitive.endsWith('ire')) {
      ending = ItalianVerbEnding.ire;
    } else {
      throw ArgumentError('Invalid Italian verb infinitive: $infinitive');
    }

    return ItalianVerb(
      infinitive: infinitive,
      ending: ending,
      isRegular: false,
      irregularForms: irregularForms,
      usesEssere: usesEssere,
    );
  }
}
