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
    String priority,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.tickets,
        data: {
          'title': title,
          'description': description,
          'category_id': categoryId,
          'priority': priority,
        },
      );
      return TicketModel.fromJson(response.data['ticket']);
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to create ticket';
    }
  }

  Future<void> uploadImage(String ticketId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      await apiClient.dio.post(
        '${ApiConstants.tickets}/$ticketId/image',
        data: formData,
      );
    } on DioException catch (e) {
      throw e.response?.data['error']['message'] ?? 'Failed to upload image';
    }
  }
}
