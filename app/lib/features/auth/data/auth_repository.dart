import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../domain/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      await storage.write(key: 'access_token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'user_id', value: data['user']['id']);
      await storage.write(key: 'user_role', value: data['user']['role']);

      return UserModel.fromJson(data['user']);
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Login failed';
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      await apiClient.dio.post(
        ApiConstants.register,
        data: {'email': email, 'password': password, 'full_name': fullName},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Registration failed';
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      final userId = await storage.read(key: 'user_id');

      if (refreshToken != null && userId != null) {
        await apiClient.dio.post(
          ApiConstants.logout,
          data: {'refresh_token': refreshToken, 'user_id': userId},
        );
      }
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await storage.deleteAll();
    }
  }

  Future<UserModel?> checkAuthStatus() async {
    final token = await storage.read(key: 'access_token');
    if (token == null) return null;

    // Optional: we can fetch user profile from an endpoint if needed,
    // or rely on decoded JWT / stored user data. I'll read from storage for simplicity if present.
    final id = await storage.read(key: 'user_id');
    final role = await storage.read(key: 'user_role');

    if (id != null && role != null) {
      return UserModel(id: id, email: '', fullName: '', role: role);
    }
    return null;
  }
}
