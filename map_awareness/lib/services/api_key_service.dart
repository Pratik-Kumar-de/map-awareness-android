import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for API keys
class ApiKeyService {
  static const _geminiKey = 'gemini_api_key';
  
  // In-memory cache to avoid repeated reads
  static String? _cachedKey;

  /// Get the stored Gemini API key
  static Future<String?> getGeminiKey() async {
    if (_cachedKey != null) return _cachedKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_geminiKey);
    return _cachedKey;
  }

  /// Save the Gemini API key
  static Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key);
    _cachedKey = key;
  }

  /// Check if a key is configured
  static Future<bool> hasGeminiKey() async {
    final key = await getGeminiKey();
    return key != null && key.isNotEmpty;
  }

  /// Clear the stored key
  static Future<void> clearGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiKey);
    _cachedKey = null;
  }
}
