import 'package:dio/dio.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';
import 'package:flutter_assesment_1/features/auth/models/signup_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AuthState({this.isLoading = false, this.error, this.isSuccess = false});

  AuthState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final Dio _dio = Dio();

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? avatar,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      // Create model instance
      // NOTE: The escuelajs API requires a valid URL for the avatar.
      // Since we don't have a real backend to upload the Base64 image to,
      // we are sending a placeholder URL to make the sign-up succeed.
      // In a real app, you would upload the `avatar` (base64) to a server first, get a URL, and send that.
      final signUpModel = SignUpModel(
        name: name,
        email: email,
        password: password,
        avatar: 'https://i.pravatar.cc/300', // Placeholder to satisfy API
      );

      // API endpoint
      const url = 'https://api.escuelajs.co/api/v1/users';

      AppLogger.info('Request URL: $url');
      AppLogger.info('Request Body: ${signUpModel.toJson()}');

      final response = await _dio.post(
        url,
        data: signUpModel.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      AppLogger.info('Response Status Code: ${response.statusCode}');
      AppLogger.info('Response Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        // Fallback for non-success codes if not caught by DioException (depends on validateStatus)
        final responseData = response.data;
        String errorMessage = 'Sign up failed';

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

        AppLogger.error('Sign Up Error: $errorMessage');
        state = state.copyWith(isLoading: false, error: errorMessage);
      }
    } on DioException catch (e) {
      String errorMessage = 'Sign up failed';
      if (e.response != null) {
        AppLogger.error('Dio Error response: ${e.response?.data}');
        final responseData = e.response?.data;

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
        errorMessage = e.message ?? 'Unknown network error';
      }

      AppLogger.error('Sign Up Exception: $errorMessage', e, e.stackTrace);
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e, stackTrace) {
      AppLogger.error('Sign Up Exception', e, stackTrace);
      state = state.copyWith(isLoading: false, error: 'An error occurred: $e');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
