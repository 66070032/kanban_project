class Task {
  final int id;
  final String title;
  final String? description;
  final String? status;
  final String? assigneeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dueAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.assigneeId,
    this.createdAt,
    this.updatedAt,
    this.dueAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      assigneeId: json['assignee_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      dueAt: json['due_at'] != null
          ? DateTime.parse(json['due_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'assignee_id': assigneeId,
      'due_at': dueAt?.toIso8601String(),
    };
  }
}