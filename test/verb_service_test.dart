import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/services/verb_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('generatePracticeSet returns only verbs valid for the selected tense', () async {
    final service = VerbService();

    final verbs = await service.generatePracticeSet(
      language: Language.italian,
      tense: VerbTense.presentSimple,
      setSize: 10,
    );

    expect(verbs, hasLength(10));
    expect(verbs.every((verb) => verb.hasTense(VerbTense.presentSimple)), isTrue);
  });
}