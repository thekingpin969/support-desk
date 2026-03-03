import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<Map<String, dynamic>> fetchAnalytics() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/admin/analytics',
      );
      if (response.data is String) {
        throw 'Invalid server response. Please check DevTunnels or backend status.';
      }
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to load analytics';
      }
      throw e.message ?? 'Unknown error occurred';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<List<dynamic>> fetchEmployees() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/admin/employees',
      );
      if (response.data is String) throw 'Invalid server response';
      return response.data['employees'];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to load employees';
      }
      throw e.message ?? 'Failed to load employees';
    }
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.baseUrl}/admin/employees',
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to create employee';
      }
      throw e.message ?? 'Failed to create employee';
    }
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.baseUrl}/admin/employees/$id',
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to update employee';
      }
      throw e.message ?? 'Failed to update employee';
    }
  }

  Future<List<dynamic>> fetchSlaConfigs() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/admin/sla-config',
      );
      if (response.data is String) throw 'Invalid server response';
      return response.data['configs'];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to load SLA configs';
      }
      throw e.message ?? 'Failed to load SLA configs';
    }
  }

  Future<void> updateSlaConfigs(List<Map<String, dynamic>> configs) async {
    try {
      await apiClient.dio.put(
        '${ApiConstants.baseUrl}/admin/sla-config',
        data: {'configs': configs},
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to update SLA configs';
      }
      throw e.message ?? 'Failed to update SLA configs';
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/admin/categories',
      );
      if (response.data is String) throw 'Invalid server response';
      return response.data['categories'];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to load categories';
      }
      throw e.message ?? 'Failed to load categories';
    }
  }

  Future<void> createCategory(String name) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.baseUrl}/admin/categories',
        data: {'name': name},
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to create category';
      }
      throw e.message ?? 'Failed to create category';
    }
  }

  Future<List<dynamic>> fetchEmployeeTickets(String employeeId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.baseUrl}/admin/employees/$employeeId/tickets',
      );
      if (response.data is String) throw 'Invalid server response';
      return response.data['tickets'];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to load employee tickets';
      }
      throw e.message ?? 'Failed to load employee tickets';
    }
  }

  Future<void> updateCategory(String id, String name, bool isActive) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.baseUrl}/admin/categories/$id',
        data: {'name': name, 'is_active': isActive},
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['error']?['message'] ??
            'Failed to update category';
      }
      throw e.message ?? 'Failed to update category';
    }
  }
}
