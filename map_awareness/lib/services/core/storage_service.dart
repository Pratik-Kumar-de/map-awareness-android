import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/models/saved_location.dart';

/// Service for persistent storage of user-saved routes and locations using SharedPreferences.
class StorageService {
  static const String _routesKey = 'saved_routes';
  static const String _locationsKey = 'saved_locations';
  static const String _themeModeKey = 'theme_mode';

  /// Returns saved theme mode (0=light, 1=dark, 2=system). Default: 0 (light).
  static Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeModeKey) ?? 0;
  }

  /// Persists theme mode preference.
  static Future<void> setThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode);
  }

  /// Generic helper to read a list of objects from shared preferences.
  static Future<List<T>> _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Generic helper to write a list of objects to shared preferences.
  static Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map(toJson).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  /// Saves or updates a route in the persistent store.
  static Future<void> saveRoute(SavedRoute route) async {
    final routes = await loadRoutes();
    final existingIndex = routes.indexWhere((r) => r.id == route.id);
    if (existingIndex >= 0) {
      routes[existingIndex] = route;
    } else {
      routes.add(route);
    }
    await _writeList(_routesKey, routes, (r) => r.toJson());
  }

  /// Loads all saved routes.
  static Future<List<SavedRoute>> loadRoutes() async {
    try {
      return await _readList(_routesKey, SavedRoute.fromJson);
    } catch (_) {
      // Skips corrupted entries, return empty.
      return [];
    }
  }

  /// Deletes a route by its ID.
  static Future<void> deleteRoute(String id) async {
    final routes = await loadRoutes();
    routes.removeWhere((r) => r.id == id);
    await _writeList(_routesKey, routes, (r) => r.toJson());
  }

  /// Saves a location, preventing duplicates based on name.
  static Future<bool> saveLocation(SavedLocation location) async {
    final locations = await loadLocations();
    
    // Checks duplicates.
    final duplicateIndex = locations.indexWhere(
      (l) => l.name.toLowerCase() == location.name.toLowerCase() && l.id != location.id
    );
    if (duplicateIndex >= 0) return false;
    
    final existingIndex = locations.indexWhere((l) => l.id == location.id);
    if (existingIndex >= 0) {
      locations[existingIndex] = location;
    } else {
      locations.add(location);
    }
    await _writeList(_locationsKey, locations, (l) => l.toJson());
    return true;
  }

  /// Removes a saved location from storage by its ID.
  static Future<void> deleteLocation(String id) async {
    final locations = await loadLocations();
    locations.removeWhere((l) => l.id == id);
    await _writeList(_locationsKey, locations, (l) => l.toJson());
  }

  /// Fetches all saved locations from the persistent store.
  static Future<List<SavedLocation>> loadLocations() =>
      _readList(_locationsKey, SavedLocation.fromJson);
}
