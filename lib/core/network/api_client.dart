import 'package:dio/dio.dart';
import 'package:flutter_assesment_1/core/network/dio_log_interceptor.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      ) {
    _dio.interceptors.add(DioLogInterceptor());
  }

  /// Generic GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Helper to upload files
  Future<dynamic> upload(
    String path, {
    required String filePath,
    String fileKey = 'file',
    Map<String, dynamic>? extraData,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final Map<String, dynamic> formDataMap = {
        fileKey: await MultipartFile.fromFile(filePath, filename: fileName),
      };

      if (extraData != null) {
        formDataMap.addAll(extraData);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    String errorMessage = 'Unexpected error occurred';
    if (error.response != null) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['message'] != null) {
          if (responseData['message'] is List) {
            errorMessage = (responseData['message'] as List).join('\n');
          } else {
            errorMessage = responseData['message'].toString();
          }
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        }
      }
    } else {
      errorMessage = error.message ?? 'Connection error';
    }
    AppLogger.error('API Error: $errorMessage', error, error.stackTrace);
    return Exception(errorMessage);
  }
}
