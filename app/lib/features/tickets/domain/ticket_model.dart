class TicketImage {
  final String id;
  final String imageUrl;

  TicketImage({required this.id, required this.imageUrl});

  factory TicketImage.fromJson(Map<String, dynamic> json) {
    return TicketImage(id: json['id'], imageUrl: json['imgbb_url'] ?? '');
  }
}

class TicketResponse {
  final String id;
  final String content;
  final String
  type; // draft, pending_review, approved, rejected, revision_requested
  final String? employeeName;
  final String? adminFeedback; // set when response is rejected
  final DateTime createdAt;

  TicketResponse({
    required this.id,
    required this.content,
    required this.type,
    this.employeeName,
    this.adminFeedback,
    required this.createdAt,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      id: json['id'],
      content: json['response_text'] ?? json['content'] ?? '',
      type: json['status'] ?? json['type'] ?? 'draft',
      employeeName: json['employee']?['full_name'],
      adminFeedback: json['admin_feedback'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? clientId;
  final Map<String, dynamic>? client; // full client object from server
  final DateTime? slaDeadline;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final List<TicketImage> images;
  final List<TicketResponse> responses;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.clientId,
    this.client,
    this.slaDeadline,
    this.resolvedAt,
    required this.createdAt,
    this.images = const [],
    this.responses = const [],
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    try {
      return TicketModel(
        id: json['id'],
        ticketNumber: json['ticket_number'],
        title: json['title'],
        description: json['description'],
        priority: json['priority'],
        status: json['status'],
        clientId: json['client_id'],
        client: json['client'] as Map<String, dynamic>?,
        slaDeadline: json['sla_deadline'] != null
            ? DateTime.parse(json['sla_deadline'])
            : null,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        images:
            (json['images'] as List<dynamic>?)
                ?.map((e) => TicketImage.fromJson(e))
                .toList() ??
            [],
        responses:
            (json['responses'] as List<dynamic>?)
                ?.map((e) => TicketResponse.fromJson(e))
                .toList() ??
            [],
      );
    } catch (e, stack) {
      print('Error parsing TicketModel: $e');
      print(stack);
      rethrow;
    }
  }
}
