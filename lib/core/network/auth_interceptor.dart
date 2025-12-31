import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final GetStorage _storage = GetStorage();
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = _storage.read('refresh_token');
      if (refreshToken != null && !_isRefreshing) {
        _isRefreshing = true;
        try {
          AppLogger.info('Token expired. Attempting refresh...');

          final tokenDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));

          final response = await tokenDio.post(
            'auth/refresh-token',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];

            AppLogger.info('Token refreshed successfully.');

            await _storage.write('access_token', newAccessToken);
            await _storage.write('refresh_token', newRefreshToken);

            // Update the original request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            // Retry the original request
            final cloneReq = await _dio.fetch(options);
            return handler.resolve(cloneReq);
          }
        } catch (e) {
          AppLogger.error('Token refresh failed', e);
          await _storage.erase(); // Logout
        } finally {
          _isRefreshing = false;
        }
      } else if (refreshToken == null) {
        // No refresh token, force logout
        await _storage.erase();
      }
    }
    return handler.next(err);
  }
}
