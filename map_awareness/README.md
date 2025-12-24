# Map Awareness

Flutter app for route planning with Autobahn API and GraphHopper integration.

## Requirements

- Flutter SDK `^3.9.2`
- Dart SDK (included with Flutter)

## Setup

```bash
# Install dependencies
flutter pub get
```

## Run

```bash
# Debug mode (hot reload)
flutter run

# Specific platform
flutter run -d windows
flutter run -d chrome
flutter run -d android
```

## Test

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Build

```bash
# Release build
flutter build windows
flutter build apk
flutter build web
```

## Project Structure

```
lib/
├── APIs/         # Autobahn & GraphHopper API clients
├── models/       # Data models (SavedRoute, SavedLocation)
├── pages/        # UI pages
├── services/     # Storage service
├── main.dart     # Entry point
└── routing.dart  # Route logic
```
