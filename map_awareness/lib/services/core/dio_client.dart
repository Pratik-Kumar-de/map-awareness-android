import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

/// Configurable HTTP client with interceptors for retries, caching, and timed-out requests.
class DioClient {
  static final Dio instance = _createDio();
  static late final CacheOptions cacheOptions;

  /// Initializes Dio with default timeouts and interceptors (Retry, Cache).
  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Configures automatic retry for failed requests (2 retries).
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      retries: 2,
      retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
    ));

    // Configures in-memory caching store.
    cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
    );
    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    return dio;
  }

  /// Generates short-term cache options (15 minutes TTL).
  static Options shortCache() => cacheOptions
      .copyWith(
        policy: CachePolicy.forceCache,
        maxStale: const Nullable(Duration(minutes: 15)),
      )
      .toOptions();

  /// Generates long-term cache options (24 hours TTL).
  static Options longCache() => cacheOptions
      .copyWith(
        policy: CachePolicy.forceCache,
        maxStale: const Nullable(Duration(hours: 24)),
      )
      .toOptions();

  /// Generates options to bypass and refresh cache.
  static Options noCache() => cacheOptions
      .copyWith(policy: CachePolicy.refresh)
      .toOptions();

  /// Safely executes a GET request and deserializes the JSON response body.
  static Future<T?> safeGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(Map<String, dynamic>) fromJson,
    String? dataKey, // Optional key to extract from response data map
  }) async {
    try {
      final res = await instance.get(path, queryParameters: queryParameters, options: options);
      final data = dataKey != null ? res.data[dataKey] : res.data;
      if (data == null) return null;
      return fromJson(data as Map<String, dynamic>);
    } catch (_) {
      // Graceful degradation: callers handle null.
      return null;
    }
  }

  /// Safely fetches a list of objects.
  static Future<List<T>> safeGetList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(Map<String, dynamic>) fromJson,
    String? listKey,
  }) async {
    try {
      final res = await instance.get(path, queryParameters: queryParameters, options: options);
      final data = listKey != null ? res.data[listKey] : res.data;
      if (data is! List) return [];
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Graceful degradation: callers handle empty list.
      return [];
    }
  }
}
