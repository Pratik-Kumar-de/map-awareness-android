import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _autobahnListKey = 'cached_autobahn_list';
  static const String _autobahnListTimestampKey = 'cached_autobahn_list_timestamp';
  static const int _autobahnListTtlHours = 24;

  static const String _routeCacheKey = 'cached_routes';
  static const int _routeCacheTtlHours = 24;

  // In-memory cache for roadworks (short-lived, 15 minutes)
  static final Map<String, _CachedData> _roadworksCache = {};
  static const int _roadworksCacheTtlMinutes = 15;

  // ============ Autobahn List Cache (24h) ============

  static Future<Map<String, dynamic>?> getCachedAutobahnList() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_autobahnListTimestampKey);
    
    if (timestamp == null) return null;
    
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = _autobahnListTtlHours * 60 * 60 * 1000;
    
    if (age > maxAge) {
      await prefs.remove(_autobahnListKey);
      await prefs.remove(_autobahnListTimestampKey);
      return null;
    }
    
    final jsonString = prefs.getString(_autobahnListKey);
    if (jsonString == null) return null;
    
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static Future<void> cacheAutobahnList(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autobahnListKey, jsonEncode(data));
    await prefs.setInt(_autobahnListTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ============ Roadworks In-Memory Cache (15 min) ============

  static List<dynamic>? getCachedRoadworks(String autobahnName) {
    final cached = _roadworksCache[autobahnName];
    if (cached == null) return null;
    
    final age = DateTime.now().difference(cached.timestamp);
    if (age.inMinutes > _roadworksCacheTtlMinutes) {
      _roadworksCache.remove(autobahnName);
      return null;
    }
    
    return cached.data as List<dynamic>;
  }

  static void cacheRoadworks(String autobahnName, List<dynamic> data) {
    _roadworksCache[autobahnName] = _CachedData(data: data, timestamp: DateTime.now());
  }

  static void clearRoadworksCache() {
    _roadworksCache.clear();
  }

  // ============ Route Response Cache (24h) ============

  static Future<Map<String, dynamic>?> getCachedRouteResponse(String startCoord, String endCoord) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routeCacheKey);
    
    if (jsonString == null) return null;
    
    final cache = jsonDecode(jsonString) as Map<String, dynamic>;
    final key = '$startCoord|$endCoord';
    
    if (!cache.containsKey(key)) return null;
    
    final entry = cache[key] as Map<String, dynamic>;
    final timestamp = entry['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = _routeCacheTtlHours * 60 * 60 * 1000;
    
    if (age > maxAge) {
      cache.remove(key);
      await prefs.setString(_routeCacheKey, jsonEncode(cache));
      return null;
    }
    
    return entry['data'] as Map<String, dynamic>;
  }

  static Future<void> cacheRouteResponse(String startCoord, String endCoord, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routeCacheKey);
    
    Map<String, dynamic> cache = {};
    if (jsonString != null) {
      cache = jsonDecode(jsonString) as Map<String, dynamic>;
    }
    
    final key = '$startCoord|$endCoord';
    cache[key] = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    
    await prefs.setString(_routeCacheKey, jsonEncode(cache));
  }
}

class _CachedData {
  final dynamic data;
  final DateTime timestamp;
  
  _CachedData({required this.data, required this.timestamp});
}
