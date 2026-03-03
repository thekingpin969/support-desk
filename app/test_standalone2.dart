import 'dart:convert';

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
  final String type;
  final String? employeeName;
  final String? adminFeedback;
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
      id: json['id']?.toString() ?? '',
      content:
          json['response_text']?.toString() ??
          json['content']?.toString() ??
          '',
      type: json['status']?.toString() ?? json['type']?.toString() ?? 'draft',
      employeeName: (json['employee'] as Map<String, dynamic>?)?['full_name']
          ?.toString(),
      adminFeedback: json['admin_feedback']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
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
            ? DateTime.parse(json['sla_deadline'].toString())
            : null,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'].toString())
            : null,
        createdAt: DateTime.parse(json['created_at'].toString()),
        images:
            (json['images'] as List<dynamic>?)
                ?.map((e) => TicketImage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        responses:
            (json['responses'] as List<dynamic>?)
                ?.map((e) => TicketResponse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e, stack) {
      print('Error parsing TicketModel: \$e');
      print(stack.toString());
      rethrow;
    }
  }
}

void main() {
  String jsonStr = '''{
    "id": "04dbb820-0bdd-468b-920b-9d6e3781b076",
    "ticket_number": "TKT-20260301-0002",
    "client_id": "3238b70a-cae2-4d09-a4c7-75f2e64ed055",
    "assigned_employee_id": "32735b53-4ae7-451c-ba46-037bb451eef8", 
    "category_id": "4b91304b-44dd-4e0a-8d45-600b4e773fb9",
    "priority": "high",
    "status": "pending_review",
    "title": "test ",
    "description": "this is for testing purpose ",
    "sla_deadline": "2026-03-01T15:44:17.384Z",
    "sla_warning_sent_at": null,
    "escalated_at": null,
    "resolved_at": null,
    "closed_at": null,
    "rating": null,
    "rating_comment": null,
    "reopen_count": 0,
    "created_at": "2026-03-01T07:44:19.084Z",
    "updated_at": "2026-03-01T07:49:56.779Z",
    "category": {
      "id": "4b91304b-44dd-4e0a-8d45-600b4e773fb9",
      "name": "Account/Access",
      "is_active": true
    },
    "client": {
      "full_name": "adithyan client ",
      "email": "thunderfooot2255@gmail.com",
      "id": "3238b70a-cae2-4d09-a4c7-75f2e64ed055"
    },
    "assigned_employee": {
      "full_name": "adithyan emp",
      "id": "32735b53-4ae7-451c-ba46-037bb451eef8",
      "email": "thunderfooot2255@gmail.com"
    },
    "images": [
      {
        "id": "2488a1b3-fd6a-4061-88c4-714b5f0ab09f",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "imgbb_url": "https://i.ibb.co/dTQvw0w/dcf51847d2ae.jpg",   
        "imgbb_delete_url": "https://ibb.co/6M4S7R7/fd95761d199403ae019f69998d7df3a2",
        "uploaded_by": "3238b70a-cae2-4d09-a4c7-75f2e64ed055",      
        "context": "ticket",
        "created_at": "2026-03-01T07:44:19.084Z"
      },
      {
        "id": "db6c0044-646c-44c9-a7dd-736a159e17c6",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "imgbb_url": "https://i.ibb.co/60WS4qKc/8fe7a8cb7587.jpg",  
        "imgbb_delete_url": "https://ibb.co/TMgGHNQD/d706b558619b583bef12dda884394289",
        "uploaded_by": "3238b70a-cae2-4d09-a4c7-75f2e64ed055",      
        "context": "ticket",
        "created_at": "2026-03-01T07:44:19.084Z"
      },
      {
        "id": "aa228a3b-1215-4022-9c3a-7e18fb381eea",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "imgbb_url": "https://i.ibb.co/WWnPWThM/bb005b15fb1d.jpg",  
        "imgbb_delete_url": "https://ibb.co/kgK9gd7w/f475783a872bc77c0b48e72a551ad308",
        "uploaded_by": "3238b70a-cae2-4d09-a4c7-75f2e64ed055",      
        "context": "ticket",
        "created_at": "2026-03-01T07:44:19.084Z"
      }
    ],
    "responses": [
      {
        "id": "a6c769bf-2e43-4deb-8712-875147d44957",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "employee_id": "32735b53-4ae7-451c-ba46-037bb451eef8",      
        "response_text": "okey, the is tickets received this to thunderfooot2255@gmail.com",
        "status": "pending_review",
        "admin_feedback": null,
        "reviewed_by": null,
        "submitted_at": "2026-03-01T07:49:52.360Z",
        "reviewed_at": null,
        "created_at": "2026-03-01T07:49:55.042Z",
        "employee": {
          "full_name": "adithyan emp"
        }
      }
    ],
    "audit_logs": [
      {
        "id": "6bd6e437-c535-48f6-b5d0-2b57aa6bf0cc",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "from_status": null,
        "to_status": "pending_review",
        "actor_id": "32735b53-4ae7-451c-ba46-037bb451eef8",
        "changed_at": "2026-03-01T07:49:56.779Z",
        "note": "Employee submitted new response for review"        
      },
      {
        "id": "442b7d8f-3e8d-4704-884e-ce8b0dc0fec8",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "from_status": "open",
        "to_status": "assigned",
        "actor_id": "32735b53-4ae7-451c-ba46-037bb451eef8",
        "changed_at": "2026-03-01T07:44:29.271Z",
        "note": "Automatically assigned to thunderfooot2255@gmail.com"
      },
      {
        "id": "89672e0e-3938-4f0f-95c7-af68cc702d53",
        "ticket_id": "04dbb820-0bdd-468b-920b-9d6e3781b076",        
        "from_status": null,
        "to_status": "open",
        "actor_id": "3238b70a-cae2-4d09-a4c7-75f2e64ed055",
        "changed_at": "2026-03-01T07:44:22.908Z",
        "note": "Ticket created"
      }
    ]
  }''';
  try {
    Map<String, dynamic> map = jsonDecode(jsonStr);
    TicketModel t = TicketModel.fromJson(map['ticket']);
    print('Success: \${t.responses.length} responses');
  } catch (e, stack) {
    print('Failed: \$e\\n\$stack');
  }
}
