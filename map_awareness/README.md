# Map Awareness

Flutter application aggregating traffic, weather, and emergency data for route planning in Germany.

## Integrations

*   **Maps & Routing**: OpenStreetMap via `flutter_map`, GraphHopper API.
*   **Traffic Data**: Autobahn GmbH API (Roadworks, Warnings).
*   **Weather Data**: DWD API (Warnings), Open-Meteo API (Conditions).
*   **Emergency Alerts**: NINA API (Federal Office for Civil Protection).
*   **Analysis**: Google Gemini API (Data summarization).

## Technical Stack

*   **Framework**: Flutter `^3.9.2`
*   **Language**: Dart
*   **Local Storage**: `shared_preferences`
*   **HTTP Client**: `http` package

## Project Structure

```
lib/
├── APIs/         # External API clients
├── components/   # Shared UI components
├── models/       # Data models and JSON serialization
├── screens/      # Info screens
│   ├── map/      # Map layer logic
│   ├── routes/   # Route calculation and management
│   ├── settings/ # Configuration
│   └── warnings/ # Warning data display
├── services/     # Data persistence and caching
├── widgets/      # Reusable widgets
└── main.dart     # Entry point
```

## Commands

### Setup

```bash
flutter pub get
```

### Run

```bash
flutter run
# Platform specific
flutter run -d windows
flutter run -d android
```

### Build

```bash
flutter build windows
flutter build apk
```
