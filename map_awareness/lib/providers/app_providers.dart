// Global provider exports for straightforward dependency injection.
export 'route_provider.dart';
export 'warning_provider.dart';
export 'input_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/services/services.dart';

// UI State Provider for persistent bottom navigation index.
final currentTabProvider = StateProvider<int>((ref) => 0);

// Theme mode provider (0=light, 1=dark, 2=system).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Saved data providers.
// Global data Providers for async loading of user-saved content.
final savedRoutesProvider = FutureProvider<List<SavedRoute>>((ref) => StorageService.loadRoutes());
final savedLocationsProvider = FutureProvider<List<SavedLocation>>((ref) => StorageService.loadLocations());

/// Initializes theme from storage. Call in main().
Future<int> loadSavedThemeMode() => StorageService.getThemeMode();


