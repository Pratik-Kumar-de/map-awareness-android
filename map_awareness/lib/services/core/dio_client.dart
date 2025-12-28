import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

/// Caching http client.
class DioClient {
  static final Dio instance = _createDio();
  static late final CacheOptions cacheOptions;

  /// Creates and configures the Dio instance with timeouts and memory caching.
  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Retry interceptor.
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      retries: 2,
      retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
    ));

    // Memory cache.
    cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
    );
    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    return dio;
  }

  /// Returns options for a short-term cache (15 minutes).
  static Options shortCache() => cacheOptions
      .copyWith(
        policy: CachePolicy.forceCache,
        maxStale: const Nullable(Duration(minutes: 15)),
      )
      .toOptions();

  /// Returns options for a long-term cache (24 hours).
  static Options longCache() => cacheOptions
      .copyWith(
        policy: CachePolicy.forceCache,
        maxStale: const Nullable(Duration(hours: 24)),
      )
      .toOptions();

  /// Returns options to force a cache refresh.
  static Options noCache() => cacheOptions
      .copyWith(policy: CachePolicy.refresh)
      .toOptions();
}
