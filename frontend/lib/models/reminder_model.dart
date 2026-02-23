class Reminder {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final bool isSent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.isSent,
    this.createdAt,
    this.updatedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      isCompleted: json['is_completed'] ?? false,
      isSent: json['is_sent'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}