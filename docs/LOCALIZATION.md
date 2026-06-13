# Sum Sprint – Localization

## Overview

The app uses Flutter's built-in internationalization system (`flutter_localizations` + `intl`) with ARB file-based code generation. This ensures **zero hardcoded user-facing strings** in any UI code.

## Current State

- **Language**: English only (`en`)
- **ARB file**: `lib/l10n/app_en.arb`
- **Generated code**: `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_en.dart`
- **Config**: `l10n.yaml` in project root

## How It Works

### 1. String Definitions (`lib/l10n/app_en.arb`)
All user-facing strings are defined as key-value pairs in the ARB file:
```json
{
  "appTitle": "Sum Sprint",
  "warmUp": "Warm Up",
  "bestScore": "{score} pts",
  ...
}
```

### 2. Code Generation
Run `flutter gen-l10n` to generate Dart classes from the ARB file. The generated `AppLocalizations` class provides type-safe getters:
```dart
final l10n = AppLocalizations.of(context);
Text(l10n.appTitle)          // "Sum Sprint"
Text(l10n.bestScore(150))    // "150 pts"
```

### 3. Configuration (`l10n.yaml`)
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

### 4. MaterialApp Setup (`main.dart`)
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  ...
)
```

## Adding a New Language (Future)

To add e.g. French:

1. Create `lib/l10n/app_fr.arb` with the same keys but French translations:
```json
{
  "@@locale": "fr",
  "appTitle": "Sum Sprint",
  "warmUp": "Échauffement",
  ...
}
```

2. Run:
```bash
flutter gen-l10n
```

3. Done! No screen code changes needed. The generated code automatically handles locale selection based on the device's language settings.

## Key Rules

- **Never hardcode strings in UI code.** Always use `AppLocalizations.of(context)!.someString`.
- **Use parameterized strings** for dynamic content: `bestScore(Object score)` generates `"{score} pts"` which is called as `l10n.bestScore(150)`.
- **Plurals and genders** can be handled via ICU message syntax in the ARB file (not currently used, but supported).
- **The ARB file is the single source of truth** for all user-facing text.
