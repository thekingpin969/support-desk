import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../domain/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

  Future<UserModel> login(String role, String email, String password) async {
    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        log('Error getting FCM token: $e');
      }

      final dataPayload = {'email': email, 'password': password};
      if (fcmToken != null) {
        dataPayload['fcm_token'] = fcmToken;
      }

      final response = await apiClient.dio.post(
        '/auth/$role/login',
        data: dataPayload,
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

  Future<void> register(
    String role,
    String email,
    String password,
    String fullName,
  ) async {
    try {
      await apiClient.dio.post(
        '/auth/$role/register',
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

  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ??
          'Forgot password request failed';
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await apiClient.dio.post(
        ApiConstants.resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Password reset failed';
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
