import 'dart:convert';
import 'lib/features/tickets/domain/ticket_model.dart';

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
    "images": [],
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
    ]
  }''';
  try {
    Map<String, dynamic> map = jsonDecode(jsonStr);
    TicketModel t = TicketModel.fromJson(map);
    print('Success: \${t.responses.length} responses');
  } catch (e, stack) {
    print('Failed: \$e\\n\$stack');
  }
}
