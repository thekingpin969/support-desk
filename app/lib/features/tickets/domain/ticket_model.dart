class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime? slaDeadline;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.slaDeadline,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      ticketNumber: json['ticket_number'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      slaDeadline: json['sla_deadline'] != null
          ? DateTime.parse(json['sla_deadline'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
