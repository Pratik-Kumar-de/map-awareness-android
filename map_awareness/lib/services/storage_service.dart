import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/models/saved_location.dart';

class StorageService {
  static const String _routesKey = 'saved_routes';
  static const String _locationsKey = 'saved_locations';

  static Future<void> saveRoute(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await loadRoutes();
    
    final existingIndex = routes.indexWhere((r) => r.id == route.id);
    if (existingIndex >= 0) {
      routes[existingIndex] = route;
    } else {
      routes.add(route);
    }
    
    final jsonList = routes.map((r) => r.toJson()).toList();
    await prefs.setString(_routesKey, jsonEncode(jsonList));
  }

  static Future<List<SavedRoute>> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routesKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((e) => SavedRoute.fromJson(e)).toList();
  }

  static Future<void> deleteRoute(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await loadRoutes();
    routes.removeWhere((r) => r.id == id);
    
    final jsonList = routes.map((r) => r.toJson()).toList();
    await prefs.setString(_routesKey, jsonEncode(jsonList));
  }

  static Future<void> saveLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await loadLocations();
    
    final existingIndex = locations.indexWhere((l) => l.id == location.id);
    if (existingIndex >= 0) {
      locations[existingIndex] = location;
    } else {
      locations.add(location);
    }
    
    final jsonList = locations.map((l) => l.toJson()).toList();
    await prefs.setString(_locationsKey, jsonEncode(jsonList));
  }

  static Future<List<SavedLocation>> loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_locationsKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((e) => SavedLocation.fromJson(e)).toList();
  }

  static Future<void> deleteLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await loadLocations();
    locations.removeWhere((l) => l.id == id);
    
    final jsonList = locations.map((l) => l.toJson()).toList();
    await prefs.setString(_locationsKey, jsonEncode(jsonList));
  }
}
