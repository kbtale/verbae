import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/models/verb.dart';
import 'package:lingua_verb_master/models/verb_catalog.dart';

void main() {
  test('parses a language catalog with regular and irregular verbs', () {
    final catalogJson = <String, dynamic>{
      'language': 'english',
      'regular': 'assets/verbs/english_regular.json',
      'irregular': 'assets/verbs/english_irregular.json',
    };

    final catalog = VerbCatalog.fromJson(catalogJson);

    expect(catalog.language, Language.english);
    expect(catalog.regularFile, 'assets/verbs/english_regular.json');
    expect(catalog.irregularFile, 'assets/verbs/english_irregular.json');
  });
}