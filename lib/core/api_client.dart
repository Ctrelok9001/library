import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../state/auth_notifier.dart';
import 'config.dart';
import 'api_exceptions.dart';

Dio buildDio(AuthNotifier authNotifier) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authNotifier.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint(
              '[API] ← ${response.requestOptions.method} ${response.requestOptions.uri} = $status');
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[API] ✗ ${error.requestOptions.uri}: ${error.type}');
        }

        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          try {
            debugPrint('[API] Токен истёк, пытаемся обновить...');
            await authNotifier.refreshTokens();

            final options = error.requestOptions;
            options.headers['Authorization'] =
                'Bearer ${authNotifier.accessToken}';
            final response = await dio.fetch(options);
            return handler.resolve(response);
          } catch (e) {
            debugPrint('[API] Не удалось обновить токен, выполняем выход');
            await authNotifier.logout();
          }
        }
        return handler.next(error);
      },
    ),
  );
  return dio;
}
