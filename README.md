## Verbae — Multilingual Verb Practice

A multilingual verb practice app (English / Spanish / Italian) built with Flutter.
Provides practice sessions, configurable practice sets, a Markdown-driven verb
ingestion pipeline, and desktop + Android builds.

Built with: Flutter, Dart, Material 3, flutter_svg, shared_preferences.

## Features
- Practice sessions with per-person input and validation
- Practice set generation with tense + category filtering (`regular` / `irregular`)
- Persisted UI preferences (category selection, etc.)
- Bulk imports for English / Spanish / Italian verb catalogs
- Desktop (Windows) and Android release builds
- Unit/widget tests for core screens and services

## Quick Demo (local)
Run the app in release mode (no debug banner) for recording or demos:

- Run on Windows:
```
flutter run -d windows --release
```
or build and run the executable:
```
flutter build windows --release
.\build\windows\x64\runner\Release\lingua_verb_master.exe
```

- Run on an Android device/emulator:
```
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell monkey -p com.verbae.app -c android.intent.category.LAUNCHER 1
```

Alternative: run in-browser for quick capture:
```
flutter run -d chrome
```

## Build artifacts
- Android APK (release): `build/app/outputs/flutter-apk/app-release.apk`
- Windows exe (release): `build/windows/x64/runner/Release/lingua_verb_master.exe`

> Note: The release APK created by this repo is signed with the debug signing
> config by default. For Play Store distribution, create and configure a
> release keystore and update `android/app/build.gradle` with a proper
> `signingConfig`.

## Verb catalogs
The app ships with built-in JSON verb catalogs located in `assets/verbs/` for
English, Spanish, and Italian. If you add tooling to author or import verbs,
place generated catalogs in that directory.

## Tests
Run unit/widget tests:
```
flutter test
```

## Development
1. Clone:
```
git clone https://github.com/<your-org>/verbae.git
cd verbae
```
2. Install dependencies:
```
flutter pub get
```
3. Run locally (see Quick Demo).

## Release & CI notes
- Android release APK path: `build/app/outputs/flutter-apk/app-release.apk`
- Consider publishing builds as GitHub Release assets (example: `gh release create`)
- For Play Store uploads build an AAB with proper release keystore:
	- Configure `android/key.properties` and `android/app/build.gradle` signing config
	- Build: `flutter build appbundle --release`

## Contributing
- Use small focused commits and descriptive messages.
- Branches: `feat/*`, `fix/*`, `chore/*`, `test/*`.
- Add tests for new features and run the suite before opening PRs.

## Credits
- App: created and maintained by the Verbae contributors
 - Verb ingestion guidance and tooling may be added to the repository; verb
	 catalogs are consumed from `assets/verbs/`.

## License
MIT
