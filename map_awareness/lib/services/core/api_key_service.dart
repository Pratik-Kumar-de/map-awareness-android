import 'package:shared_preferences/shared_preferences.dart';

/// Service for securely managing API keys using shared preferences.
class ApiKeyService {
  static const _geminiKey = 'gemini_api_key';
  
  // Caches key.
  static String? _cachedKey;

  /// Retrieves the Gemini API key from cache or storage.
  static Future<String?> getGeminiKey() async {
    if (_cachedKey != null) return _cachedKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_geminiKey);
    return _cachedKey;
  }

  /// Persists the Gemini API key to storage and updates cache.
  static Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key);
    _cachedKey = key;
  }

  /// Checks if a valid API key exists.
  static Future<bool> hasGeminiKey() async {
    final key = await getGeminiKey();
    return key != null && key.isNotEmpty;
  }

  /// Removes the stored API key.
  static Future<void> clearGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiKey);
    _cachedKey = null;
  }
}
