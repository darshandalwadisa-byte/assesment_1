import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';
import 'package:flutter_assesment_1/core/network/api_client.dart';
import 'package:flutter_assesment_1/core/network/api_provider.dart';
import 'package:flutter_assesment_1/features/auth/models/signup_model.dart';

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
  late final ApiClient _apiClient;

  @override
  AuthState build() {
    _apiClient = ref.read(apiClientProvider);
    return const AuthState();
  }

  Future<String?> _uploadImage(String filePath) async {
    try {
      const path = 'files/upload';

      final dynamic responseData = await _apiClient.upload(
        path,
        filePath: filePath,
      );

      if (responseData != null) {
        return responseData['location'] as String?;
      }
    } catch (e, stack) {
      AppLogger.error('Image Upload Failed', e, stack);
    }
    return null;
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? imagePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      String avatarUrl = 'https://i.pravatar.cc/300'; // Default placeholder

      if (imagePath != null) {
        final uploadedUrl = await _uploadImage(imagePath);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        } else {
          // If upload fails, keep default or handle error.
          // For now, we'll proceed with default but log it.
          AppLogger.warning('Using default avatar due to upload failure.');
        }
      }

      final signUpModel = SignUpModel(
        name: name,
        email: email,
        password: password,
        avatar: avatarUrl,
      );

      // API endpoint
      const path = 'users';

      AppLogger.info('Request URL: $path');
      AppLogger.info('Request Body: ${signUpModel.toJson()}');

      final dynamic responseData = await _apiClient.post(
        path,
        data: signUpModel.toJson(),
      );

      AppLogger.info('Response Body: $responseData');

      // If no exception thrown, assume success (ApiClient throws on error)
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, stackTrace) {
      // ApiClient returns Exception with error message
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      AppLogger.error('Sign Up Exception: $errorMessage', e, stackTrace);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
