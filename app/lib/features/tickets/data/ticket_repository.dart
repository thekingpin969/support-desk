import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../domain/ticket_model.dart';

class TicketRepository {
  final ApiClient apiClient;

  TicketRepository({required this.apiClient});

  Future<List<TicketModel>> fetchTickets() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.tickets);
      final List data = response.data['tickets'];
      return data.map((e) => TicketModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to load tickets';
    }
  }

  Future<TicketModel> createTicket(
    String title,
    String description,
    String categoryId,
    String priority, {
    List<Map<String, String>>? images,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.tickets,
        data: {
          'title': title,
          'description': description,
          'category_id': categoryId,
          'priority': priority,
          if (images != null) 'images': images,
        },
      );
      return TicketModel.fromJson(response.data['ticket']);
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to create ticket';
    }
  }

  Future<Map<String, String>> uploadImageObj(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final res = await apiClient.dio.post(ApiConstants.upload, data: formData);
      final data = res.data['data'];
      return {
        'imgbb_url': data['imgbb_url'],
        'imgbb_delete_url': data['imgbb_delete_url'],
      };
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to upload image';
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  Future<void> uploadImage(
    String ticketId,
    String filePath, {
    String context = 'ticket',
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
        'context': context,
      });
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/images',
        data: formData,
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to upload image';
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  Future<void> createResponse(
    String ticketId,
    String content, {
    List<String>? imagePaths,
    String status = 'pending_review',
  }) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/responses',
        data: {'response_text': content, 'status': status},
      );
      // Upload images AFTER response is created, using 'response' context
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (final path in imagePaths) {
          await uploadImage(ticketId, path, context: 'response');
        }
      }
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to create response';
    }
  }

  Future<Map<String, dynamic>?> fetchDraftResponse(String ticketId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.tickets}/$ticketId',
      );
      final ticket = response.data['ticket'];
      final responses = ticket['responses'] as List? ?? [];
      // Find an existing draft response for this employee
      final draft = responses.firstWhere(
        (r) => r['status'] == 'draft' || r['status'] == 'revision_requested',
        orElse: () => null,
      );
      return draft as Map<String, dynamic>?;
    } on DioException {
      return null;
    }
  }

  Future<void> approveResponse(String ticketId, String responseId) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/responses/$responseId/approve',
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ??
          'Failed to approve response';
    }
  }

  Future<void> rejectResponse(
    String ticketId,
    String responseId, {
    String? feedback,
  }) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/responses/$responseId/reject',
        data: feedback != null ? {'feedback': feedback} : {},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to reject response';
    }
  }

  Future<void> reassignTicket(String ticketId, String employeeId) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/reassign',
        data: {'employee_id': employeeId},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to reassign ticket';
    }
  }

  Future<void> escalateTicket(String ticketId) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/escalate-notify',
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to escalate ticket';
    }
  }

  Future<void> rateTicket(String ticketId, int rating, String comment) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/rate',
        data: {'rating': rating, 'rating_comment': comment},
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to rate ticket';
    }
  }

  Future<void> reopenTicket(String ticketId) async {
    try {
      await apiClient.dio.post('${ApiConstants.tickets}/$ticketId/reopen');
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to reopen ticket';
    }
  }

  Future<Map<String, String>> fetchCategories() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.tickets}/categories',
      );
      final List data = response.data['categories'];
      final Map<String, String> categories = {};
      for (var cat in data) {
        if (cat['is_active'] == true) {
          categories[cat['id']] = cat['name'];
        }
      }
      return categories;
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to load categories';
    }
  }
}
