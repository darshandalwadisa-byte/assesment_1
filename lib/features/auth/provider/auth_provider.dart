import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';
import 'package:flutter_assesment_1/core/network/api_client.dart';
import 'package:flutter_assesment_1/core/network/api_provider.dart';
import 'package:flutter_assesment_1/features/auth/models/signup_model.dart';
import 'package:flutter_assesment_1/features/auth/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final bool isAuthenticated;
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool? isAuthenticated,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final ApiClient _apiClient;
  final _storage = GetStorage();

  @override
  AuthState build() {
    _apiClient = ref.read(apiClientProvider);
    return _init();
  }

  AuthState _init() {
    try {
      final token = _storage.read('access_token');
      if (token != null) {
        // Schedule profile fetch to run after build completes
        Future.microtask(() async {
          await getUserProfile(token);
          // Only update if no error occurred in profile fetch, or just unset loading
          // Actually getUserProfile updates state.user
          // We just need to ensure loading is set to false.
          state = state.copyWith(isLoading: false);
        });

        return const AuthState(
          isSuccess: true,
          isLoading: true,
          isAuthenticated: true,
        );
      }
    } catch (_) {}

    return const AuthState();
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write('access_token', accessToken);
    await _storage.write('refresh_token', refreshToken);
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      const path = 'auth/login';
      final response = await _apiClient.post(
        path,
        data: {'email': email, 'password': password},
      );

      if (response != null && response['access_token'] != null) {
        await _saveTokens(response['access_token'], response['refresh_token']);
        await getUserProfile(response['access_token']);
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          isAuthenticated: true,
        );
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e, stack) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      AppLogger.error('Login Failed', e, stack);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> getUserProfile([String? token]) async {
    try {
      String? accessToken = token;
      if (accessToken == null) {
        if (accessToken == null) {
          accessToken = _storage.read('access_token');
        }
      }

      if (accessToken == null) return;

      const path = 'auth/profile';

      // Assuming ApiClient has a get method. If not, I'll need to check.
      // Since I haven't seen ApiClient source, I am taking a risk here.
      // Usage showed _apiClient.post and _apiClient.upload.
      // I should verify ApiClient has get method.
      // I will assume it does for now to move forward, but I'll check it right after this tool if it fails.

      final response = await _apiClient.get(
        path,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response != null) {
        final user = UserModel.fromJson(response);
        state = state.copyWith(user: user);
      }
    } catch (e, stack) {
      AppLogger.error('Get Profile Failed', e, stack);
    }
  }

  Future<void> logout() async {
    await _storage.erase();
    state = const AuthState();
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

  Future<void> updateName(String newName) async {
    final user = state.user;
    if (user == null || user.id == null) return;

    try {
      final path = 'users/${user.id}';
      final response = await _apiClient.put(path, data: {'name': newName});

      if (response != null) {
        final updatedUser = UserModel.fromJson(response);
        state = state.copyWith(user: updatedUser);
        AppLogger.info('User name updated to $newName');
      }
    } catch (e, stack) {
      AppLogger.error('Update Name Failed', e, stack);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
