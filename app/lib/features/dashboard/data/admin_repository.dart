import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<Map<String, dynamic>> fetchAnalytics() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/v1/admin/analytics',
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to load analytics';
    }
  }

  Future<List<dynamic>> fetchEmployees() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/v1/admin/employees',
      );
      return response.data['employees'];
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to load employees';
    }
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.baseUrl}/v1/admin/employees',
        data: data,
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to create employee';
    }
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.baseUrl}/v1/admin/employees/$id',
        data: data,
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to update employee';
    }
  }

  Future<List<dynamic>> fetchSlaConfigs() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/v1/admin/sla-config',
      );
      return response.data['configs'];
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ??
          'Failed to load SLA configs';
    }
  }

  Future<void> updateSlaConfigs(List<Map<String, dynamic>> configs) async {
    try {
      await apiClient.dio.put(
        '${ApiConstants.baseUrl}/v1/admin/sla-config',
        data: {'configs': configs},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ??
          'Failed to update SLA configs';
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/v1/admin/categories',
      );
      return response.data['categories'];
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to load categories';
    }
  }

  Future<void> createCategory(String name) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.baseUrl}/v1/admin/categories',
        data: {'name': name},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to create category';
    }
  }

  Future<void> updateCategory(String id, String name, bool isActive) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.baseUrl}/v1/admin/categories/$id',
        data: {'name': name, 'is_active': isActive},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to update category';
    }
  }
}
