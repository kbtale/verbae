# Verbae — Verb Data Format Specification

## Overview

Verbae loads verb conjugations from JSON files in `assets/verbs/`. Each file represents a single language and follows a unified catalog format. The loader (`VerbService`) reads these files, parses them into `Verb` model objects, and generates practice sets for any supported language/tense combination.

## Catalog Structure

Each language catalog is a JSON object with two top-level keys:

```json
{
  "language": "english",
  "verbs": [ ... ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `language` | string | Yes | One of: `"english"`, `"italian"`, `"spanish"` |
| `verbs` | array | Yes | List of verb entries (regular or irregular) |

## Verb Entry — Regular

A regular verb provides conjugation rules as template strings. The `{base}` token is replaced with the verb stem during conjugation.

```json
{
  "type": "regular",
  "base": "parlare",
  "language": "italian",
  "category": "regular",
  "conjugation_rules": {
    "present_simple": {
      "affirmative": {
        "io": "{base}o",
        "tu": "{base}i"
      }
    }
  },
  "spelling_rules": {
    "default": "regular"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Must be `"regular"` |
| `base` | string | Yes | Infinitive form (e.g. `"parlare"`, `"walk"`, `"hablar"`). Must be non-empty, trimmed. |
| `language` | string | Yes | Must match the catalog's `language` value |
| `category` | string | Yes | Verb category. Currently `"regular"` or `"irregular"` |
| `conjugation_rules` | object | Yes | Tense → form → subject → template string map |
| `spelling_rules` | object | Yes | Spelling rule hints. Minimum: `{"default": "regular"}` |

## Verb Entry — Irregular

An irregular verb provides explicit conjugated forms instead of templates.

```json
{
  "type": "irregular",
  "base": "essere",
  "language": "italian",
  "category": "irregular",
  "forms": {
    "present_simple": {
      "affirmative": {
        "io": "sono",
        "tu": "sei",
        "luiLei": "è"
      }
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Must be `"irregular"` |
| `base` | string | Yes | Infinitive form. Must be non-empty, trimmed. |
| `language` | string | Yes | Must match the catalog's `language` value |
| `category` | string | Yes | Typically `"irregular"` |
| `forms` | object | Yes | Tense → form → subject → conjugated string map |

## Supported Languages

| Language | JSON value | File | Subjects |
|----------|-----------|------|----------|
| English | `"english"` | `assets/verbs/english.json` | `I`, `you`, `he/she/it`, `we`, `they` |
| Italian | `"italian"` | `assets/verbs/italian.json` | `io`, `tu`, `luiLei`, `noi`, `voi`, `loro` |
| Spanish | `"spanish"` | `assets/verbs/spanish.json` | `yo`, `tu`, `elEllaUsted`, `nosotros`, `vosotros`, `ellosEllasUstedes` |

## Supported Tenses

| Enum | JSON key | Example (English) |
|------|----------|-------------------|
| `VerbTense.presentSimple` | `"present_simple"` | I walk |
| `VerbTense.presentContinuous` | `"present_continuous"` | I am walking |
| `VerbTense.pastSimple` | `"past_simple"` | I walked |
| `VerbTense.pastContinuous` | `"past_continuous"` | I was walking |
| `VerbTense.futureSimple` | `"future_simple"` | I will walk |
| `VerbTense.futureContinuous` | `"future_continuous"` | I will be walking |

Not every verb must define all tenses. A verb only needs the tenses it supports. Practice sets filter to verbs that have the selected tense.

## Supported Forms

| Enum | JSON key | Example (English, I, walk) |
|------|----------|---------------------------|
| `VerbForm.affirmative` | `"affirmative"` | I walk |
| `VerbForm.negative` | `"negative"` | I do not walk |
| `VerbForm.question` | `"question"` | Do I walk |

Practice currently uses `affirmative` forms only. Negative and question forms are defined in the catalog for future use.

## Template Syntax

Regular verbs use the `{base}` token inside conjugation template strings:

```
"{base}o" → "parlo"       (Italian: stem = parl)
"{base}s" → "walks"       (English: stem = walk, applies 3rd-person rule)
"will {base}" → "will walk" (English: no suffix transformation)
```

### Stem Extraction

The template engine extracts the verb stem before substitution:

| Language | Rule | Example |
|----------|------|---------|
| Italian | Strip `-are`, `-ere`, `-ire` (3 chars) | `parlare` → `parl` |
| Spanish | Strip `-ar`, `-er`, `-ir` (2 chars) | `hablar` → `habl` |
| English | Full base (no stripping) | `walk` → `walk` |

### English Spelling Rules (applied on `{base}s`, `{base}ed`, `{base}ing`)

| Suffix | Rule |
|--------|------|
| 3rd person (`{base}s`) | Ends in s/sh/ch/x/z/o → add `es`. Consonant+y → `ies`. Otherwise `s`. |
| Past tense (`{base}ed`) | Ends in e → add `d`. Consonant+y → `ied`. CVC pattern → double consonant + `ed`. Otherwise `ed`. |
| Present participle (`{base}ing`) | Ends in ie → `ying`. Ends in e → drop e + `ing`. CVC pattern → double consonant + `ing`. Otherwise `ing`. |

## Validation Rules

The loader (`Verb.fromJson`, `VerbCatalog.fromJson`) rejects:

1. **Empty or whitespace-only `base`** — throws `FormatException`
2. **Missing `base` field** — throws `FormatException`
3. **Verb `language` does not match catalog `language`** — throws `FormatException`
4. **Catalog file is not a JSON object** — throws `FormatException`
5. **Unknown `type` value** — treated as irregular (falls back to `forms`)
6. **Missing `conjugation_rules` on regular verbs** — verb may have no tenses (empty practice set)

## Adding a New Language

1. **Create the asset file** at `assets/verbs/{language}.json` following the catalog structure above.
2. **Add the language to the `Language` enum** in `lib/models/verb.dart`.
3. **Register the file** in `lib/services/verb_service.dart` `_verbFiles` map:
   ```dart
   Language.newLanguage: 'assets/verbs/new_language.json',
   ```
4. **Add conjugation rules** in `VerbService._regularConjugationRules()` — define the template patterns for each tense/subject/form for your language. This is required for the legacy regular-verb loader fallback.
5. **Add spelling rules** in `VerbService._regularSpellingRules()` — return `{"default": "regular"}` for non-English languages.
6. **Define subjects** — the practice screen creates one input field per subject in the conjugation map. Subjects should be human-readable labels in the target language.
7. **Add verbs** to the catalog JSON file following the regular or irregular entry format above.

## File Locations

| File | Purpose |
|------|---------|
| `lib/models/verb.dart` | `Verb`, `VerbTense`, `VerbForm`, `Language` enums |
| `lib/models/verb_catalog.dart` | `VerbCatalog` — parses the top-level catalog JSON |
| `lib/services/verb_service.dart` | Loader, caching, practice set generation, conjugation rule definitions |
| `assets/verbs/*.json` | Verb data for each supported language |
