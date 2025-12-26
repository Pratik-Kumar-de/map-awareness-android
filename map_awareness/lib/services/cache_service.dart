import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:map_awareness/APIs/dwd_api.dart';
import 'package:map_awareness/APIs/nina_api.dart';

class CacheService {
  static const String _autobahnListKey = 'cached_autobahn_list';
  static const String _autobahnListTimestampKey = 'cached_autobahn_list_timestamp';
  static const int _autobahnListTtlHours = 24;

  static const String _routeCacheKey = 'cached_routes';
  static const int _routeCacheTtlHours = 24;

  // In-memory caches (short-lived, 15 minutes)
  static final Map<String, _CachedData> _roadworksCache = {};
  static _CachedData? _dwdWarningsCache;
  static final Map<String, _CachedData> _ninaWarningsCache = {};
  static const int _warningsCacheTtlMinutes = 15;

  // ============ Autobahn List Cache (24h) ============

  static Future<Map<String, dynamic>?> getCachedAutobahnList() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_autobahnListTimestampKey);
    if (timestamp == null) return null;
    
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _autobahnListTtlHours * 60 * 60 * 1000) {
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
    if (DateTime.now().difference(cached.timestamp).inMinutes > _warningsCacheTtlMinutes) {
      _roadworksCache.remove(autobahnName);
      return null;
    }
    return cached.data as List<dynamic>;
  }

  static void cacheRoadworks(String autobahnName, List<dynamic> data) {
    _roadworksCache[autobahnName] = _CachedData(data: data, timestamp: DateTime.now());
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
    if (DateTime.now().millisecondsSinceEpoch - timestamp > _routeCacheTtlHours * 60 * 60 * 1000) {
      cache.remove(key);
      await prefs.setString(_routeCacheKey, jsonEncode(cache));
      return null;
    }
    return entry['data'] as Map<String, dynamic>;
  }

  static Future<void> cacheRouteResponse(String startCoord, String endCoord, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routeCacheKey);
    
    Map<String, dynamic> cache = jsonString != null ? jsonDecode(jsonString) : {};
    cache['$startCoord|$endCoord'] = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString(_routeCacheKey, jsonEncode(cache));
  }

  // ============ DWD Warnings Cache (15 min) ============

  static List<DWDWarning>? getCachedDWDWarnings() {
    if (_dwdWarningsCache == null) return null;
    if (DateTime.now().difference(_dwdWarningsCache!.timestamp).inMinutes > _warningsCacheTtlMinutes) {
      _dwdWarningsCache = null;
      return null;
    }
    return _dwdWarningsCache!.data as List<DWDWarning>;
  }

  static void cacheDWDWarnings(List<DWDWarning> data) {
    _dwdWarningsCache = _CachedData(data: data, timestamp: DateTime.now());
  }

  // ============ NINA Warnings Cache (15 min) ============

  static List<NINAWarning>? getCachedNINAWarnings(String ars) {
    final cached = _ninaWarningsCache[ars];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp).inMinutes > _warningsCacheTtlMinutes) {
      _ninaWarningsCache.remove(ars);
      return null;
    }
    return cached.data as List<NINAWarning>;
  }

  static void cacheNINAWarnings(String ars, List<NINAWarning> data) {
    _ninaWarningsCache[ars] = _CachedData(data: data, timestamp: DateTime.now());
  }
}

class _CachedData {
  final dynamic data;
  final DateTime timestamp;
  _CachedData({required this.data, required this.timestamp});
}
