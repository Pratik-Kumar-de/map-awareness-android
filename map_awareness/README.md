# Map Awareness

Application for aggregating traffic, environmental, and emergency data in Germany.

## Integrations

| Domain | Provider | Implementation |
| :--- | :--- | :--- |
| **Routing** | GraphHopper | `services/location/` |
| **Traffic** | Autobahn GmbH | `services/data/traffic_service.dart` |
| **Weather** | DWD | `services/data/warning_service.dart` |
| **Civil Defense** | NINA | `services/data/warning_service.dart` |
| **Environment** | Open-Meteo | `services/data/environment_service.dart` |
| **AI Summary** | Google Gemini | `services/data/gemini_service.dart` |

## Project Structure

```text
lib/
├── data/                    # Static datasets and ARS lookups
├── models/                  # Domain models (Internal state)
│   └── dto/                 # Data Transfer Objects (External API responses)
├── providers/               # Riverpod state management providers
├── router/                  # GoRouter configuration and route definitions
├── screens/                 # Application views associated with routes
│   ├── map/                 # Map interface and layer visualization
│   ├── routes/              # Route planning and management interfaces
│   ├── settings/            # Application configuration
│   └── warnings/            # Warning lists and details
├── services/                # Backend integration and business logic
│   ├── core/                # Infrastructure (HTTP, Storage, API types)
│   ├── data/                # Data fetching (Traffic, Weather, Environment)
│   └── location/            # Geolocation, Geocoding, and Routing
├── utils/                   # Shared utilities and Theme definitions
└── widgets/                 # Reusable UI components
    ├── buttons/             # Button variants
    ├── cards/               # Data display containers
    ├── common/              # Shared UI elements (Loaders, Badges)
    ├── feedback/            # Visual feedback components
    ├── inputs/              # Form fields and search inputs
    └── layout/              # Structural components (AppShell)
```

## Setup & Configuration

### Prerequisites
*   Flutter SDK
*   Dart SDK

### 1. Installation
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. API Keys

| Service | Purpose | Configuration Method |
| :--- | :--- | :--- |
| **Google Gemini** | AI Summaries | **In-App:** Go to *Settings* > *API Key* to enter your key. |
| **GraphHopper** | Routing/Geocoding | **Source:** Update `apiKey` in `lib/services/location/geocoding_service.dart`. |

## Running & Building

### Development
```bash
# Run on connected device
flutter run

# Run on Windows desktop
flutter run -d windows
```

### Production

**Android APK**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Windows Executable**
```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

## Tech Stack
- **Framework**: Flutter / Dart
- **State**: Riverpod
- **Maps**: Flutter Map (OSM)
- **Data**: Dio, json_serializable
- **Theming**: FlexColorScheme
