import 'verb.dart';

class VerbCatalog {
  final Language language;
  final String regularFile;
  final String irregularFile;

  VerbCatalog({
    required this.language,
    required this.regularFile,
    required this.irregularFile,
  });

  factory VerbCatalog.fromJson(Map<String, dynamic> json) {
    final languageValue = json['language'] as String?;
    if (languageValue == null) {
      throw FormatException('Missing language in verb catalog.');
    }

    final regularFile = json['regular'] as String?;
    if (regularFile == null) {
      throw FormatException('Missing regular file in verb catalog.');
    }

    final irregularFile = json['irregular'] as String?;
    if (irregularFile == null) {
      throw FormatException('Missing irregular file in verb catalog.');
    }

    return VerbCatalog(
      language: _parseLanguage(languageValue),
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