import 'verb.dart';

class VerbCatalog {
  final Language language;
  final List<Verb> verbs;
  final String regularFile;
  final String irregularFile;

  VerbCatalog({
    required this.language,
    required this.verbs,
    required this.regularFile,
    required this.irregularFile,
  });

  factory VerbCatalog.fromJson(Map<String, dynamic> json) {
    final languageValue = json['language'] as String?;
    if (languageValue == null) {
      throw const FormatException('Missing language in verb catalog.');
    }

    final catalogLanguage = _parseLanguage(languageValue);

    final verbsValue = json['verbs'];
    final verbs = verbsValue is List
        ? verbsValue
            .cast<Map<String, dynamic>>()
            .map((verbJson) {
              final verbLanguage = verbJson['language'] as String?;
              if (verbLanguage != null && verbLanguage != languageValue) {
                throw FormatException(
                  'Verb entry language must match catalog language: $verbLanguage != $languageValue',
                );
              }
              return Verb.fromJson(verbJson);
            })
            .toList(growable: false)
        : <Verb>[];

    final regularFile = json['regular'] as String? ?? '';
    final irregularFile = json['irregular'] as String? ?? '';

    if (verbs.isEmpty && (regularFile.isEmpty || irregularFile.isEmpty)) {
      throw const FormatException('Verb catalog must define either verbs or regular and irregular files.');
    }

    return VerbCatalog(
      language: catalogLanguage,
      verbs: verbs,
      regularFile: regularFile,
      irregularFile: irregularFile,
    );
  }

  static Language _parseLanguage(String language) {
    switch (language) {
      case 'english':
        return Language.english;
      case 'italian':
        return Language.italian;
      case 'spanish':
        return Language.spanish;
    }

    throw FormatException('Unsupported language in verb catalog: $language');
  }
}