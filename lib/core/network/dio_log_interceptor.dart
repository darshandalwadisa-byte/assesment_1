import 'package:dio/dio.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';

class DioLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('🌐 REST Request: [${options.method}] ${options.uri}');

    if (options.data != null) {
      AppLogger.info('📝 Request Body: ${options.data}');
    }

    if (options.queryParameters.isNotEmpty) {
      AppLogger.info('❓ Query Params: ${options.queryParameters}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      '✅ REST Response: [${response.statusCode}] ${response.requestOptions.uri}',
    );

    // Log response data if present
    if (response.data != null) {
      AppLogger.info('📦 Response Data: ${response.data}');
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '⛔ REST Error: [${err.response?.statusCode}] ${err.requestOptions.uri}',
      err.error,
      err.stackTrace,
    );

    if (err.response?.data != null) {
      AppLogger.error('❌ Error Body: ${err.response?.data}');
    }

    super.onError(err, handler);
  }
}
