# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get        # Install dependencies
flutter analyze        # Run linter (uses flutter_lints)
flutter test           # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter run            # Run in debug mode
flutter build apk      # Build Android APK
flutter build ios      # Build iOS
flutter build web      # Build web
```

## Architecture

This is a Flutter playground/learning project targeting mobile, web, and desktop.

**State management:** Built-in `StatefulWidget` + `setState()` only — no external state management library.

**Entry point:** `lib/main.dart` — defines `MyApp` (root widget with Material 3 theme using `Colors.deepPurple` seed) and `MyHomePage` (stateful counter + user profile card UI).

**Additional files:** `lib/counter_screen.dart` contains standalone algorithm practice code (not linked to the main app UI).

**Testing:** `test/widget_test.dart` — basic widget smoke tests using `flutter_test`.

**Dart SDK requirement:** `^3.11.5`
