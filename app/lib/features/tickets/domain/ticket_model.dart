import 'package:flutter/foundation.dart';

class TicketImage {
  final String id;
  final String imageUrl;

  TicketImage({required this.id, required this.imageUrl});

  factory TicketImage.fromJson(Map<String, dynamic> json) {
    return TicketImage(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imgbb_url']?.toString() ?? '',
    );
  }
}

class TicketResponse {
  final String id;
  final String content;
  final String
  type; // draft, pending_review, approved, rejected, revision_requested
  final String? employeeName;
  final String? adminFeedback; // set when admin asks for revision
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
    // Safely extract employee name from nested object
    String? empName;
    final empRaw = json['employee'];
    if (empRaw is Map) {
      empName = empRaw['full_name']?.toString();
    }

    return TicketResponse(
      id: json['id']?.toString() ?? '',
      content:
          json['response_text']?.toString() ??
          json['content']?.toString() ??
          '',
      type: json['status']?.toString() ?? json['type']?.toString() ?? 'draft',
      employeeName: empName,
      adminFeedback: json['admin_feedback']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
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
      // Defensive parsing: use .toString() on all fields to prevent
      // silent TypeErrors from Dart 3 strict type safety with dynamic JSON.
      final clientRaw = json['client'];
      Map<String, dynamic>? clientMap;
      if (clientRaw is Map) {
        clientMap = Map<String, dynamic>.from(clientRaw);
      }

      return TicketModel(
        id: json['id']?.toString() ?? '',
        ticketNumber: json['ticket_number']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'medium',
        status: json['status']?.toString() ?? 'open',
        clientId: json['client_id']?.toString(),
        client: clientMap,
        slaDeadline: json['sla_deadline'] != null
            ? DateTime.tryParse(json['sla_deadline'].toString())
            : null,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.tryParse(json['resolved_at'].toString())
            : null,
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        images: _parseImages(json['images']),
        responses: _parseResponses(json['responses'] ?? json['response']),
      );
    } catch (e, stack) {
      debugPrint('Error parsing TicketModel: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  static List<TicketImage> _parseImages(dynamic imagesJson) {
    if (imagesJson == null || imagesJson is! List) return [];
    List<TicketImage> result = [];
    for (var img in imagesJson) {
      try {
        if (img is Map) {
          result.add(TicketImage.fromJson(Map<String, dynamic>.from(img)));
        }
      } catch (e) {
        debugPrint('Skipping a malformed image: $e');
      }
    }
    return result;
  }

  static List<TicketResponse> _parseResponses(dynamic responsesJson) {
    if (responsesJson == null || responsesJson is! List) return [];
    List<TicketResponse> result = [];
    for (var r in responsesJson) {
      try {
        if (r is Map) {
          result.add(TicketResponse.fromJson(Map<String, dynamic>.from(r)));
        }
      } catch (e) {
        debugPrint('Skipping a malformed response: $e');
      }
    }
    return result;
  }
}
