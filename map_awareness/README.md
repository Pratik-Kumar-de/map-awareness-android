# Map Awareness

Application for aggregating traffic, environmental, and emergency data in Germany.

## Features

### Map
- OSM-based map with OpenStreetMap tiles
- Route polyline visualization with start/end markers
- Markers for roadworks, charging stations, parking areas, warnings
- Tap-to-select location for route start/destination
- Alternative route polyline display
- Zoom/recenter controls
- Bottom sheet details for each marker type

### Routing
- Route calculation via GraphHopper API
- Alternative routes (up to 3 paths)
- Route selection and switching
- Autobahn segment extraction from routes
- Roadwork filtering by route segments (ongoing/short-term/future)
- Charging station and parking area filtering by route
- Departure and arrival weather forecasts
- AI-generated route summary (roadworks, warnings, weather)
- Save/load/delete routes with persistent storage

### Warnings
- DWD weather warnings (German Weather Service)
- NINA civil defense warnings via ARS lookup
- Location-based search with geocoding
- Radius filter (km)
- Severity and category filtering
- Current weather display (temperature, wind, precipitation)
- Air quality index (US AQI, PM2.5, PM10)
- Flood risk data (river discharge)
- AI-generated location safety summary
- Save/load/delete locations with persistent storage

### Settings
- Dark mode / Light mode / System theme toggle
- Gemini API key management (in-app)
- Privacy information display

### General
- Riverpod state management
- Parallel API calls with Future.wait
- HTTP caching (short/long cache)
- Retry logic via dio_smart_retry
- Skeleton loading states
- Toast notifications
- Haptic feedback
- Pull-to-refresh
- Adaptive layout

## Integrations

| Domain | Provider | Implementation |
| :--- | :--- | :--- |
| **Routing** | GraphHopper | `services/location/routing_service.dart` |
| **Geocoding** | GraphHopper | `services/location/geocoding_service.dart` |
| **Traffic** | Autobahn GmbH | `services/data/traffic_service.dart` |
| **Weather Warnings** | DWD | `services/data/warning_service.dart` |
| **Civil Defense** | NINA | `services/data/warning_service.dart` |
| **Weather Forecast** | Open-Meteo | `services/data/environment_service.dart` |
| **Air Quality** | Open-Meteo | `services/data/environment_service.dart` |
| **Flood Data** | Open-Meteo | `services/data/environment_service.dart` |
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
└── widgets/                 # UI components
    ├── buttons/             # Button variants
    ├── cards/               # Data display containers
    ├── common/              # UI elements (Loaders, Badges)
    ├── feedback/            # Visual feedback components
    ├── inputs/              # Form fields and search inputs
    └── layout/              # Structural components (AppShell)
```

## Setup & Configuration

### Prerequisites
- Flutter SDK
- Dart SDK

### Installation
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### API Keys

| Service | Purpose | Configuration |
| :--- | :--- | :--- |
| **Google Gemini** | AI Summaries | In-App: Settings > API Key |
| **GraphHopper** | Routing/Geocoding | Source: `lib/services/location/geocoding_service.dart` |

## Running & Building

### Development
```bash
flutter run
flutter run -d windows
```

### Production
```bash
# Android
flutter build apk --release

# Windows
flutter build windows --release
```

## Tech Stack
- **Framework**: Flutter / Dart
- **State**: Riverpod
- **Storage**: Shared Preferences
- **Maps**: Flutter Map (OSM), latlong2
- **Location**: Geolocator
- **HTTP**: Dio, dio_smart_retry
- **Serialization**: json_serializable
- **Theme**: FlexColorScheme, Google Fonts
- **UI**: Toastification, Shimmer, Slidable, Page Transition
- **Utils**: Timeago, Collection, Clock
