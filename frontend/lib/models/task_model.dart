import '../core/config/app_config.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final String? status;
  final String? assigneeId;
  final String? assigneeName;
  final int? groupId;
  final String? groupName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dueAt;
  final String? voiceInstructionUrl;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.assigneeId,
    this.assigneeName,
    this.groupId,
    this.groupName,
    this.createdAt,
    this.updatedAt,
    this.dueAt,
    this.voiceInstructionUrl,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      assigneeId: json['assignee_id']?.toString(),
      assigneeName: json['assignee_name'],
      groupId: json['group_id'],
      groupName: json['group_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at']) : null,
      voiceInstructionUrl: json['voice_instruction_uuid'] != null
          ? '${AppConfig.baseUrl}/uploads/${json['voice_instruction_uuid']}'
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

  /// Whether this task came from a group chat
  bool get isFromGroup => groupId != null;

  /// Display label for task origin
  String get originLabel => isFromGroup ? groupName ?? 'Group' : 'Personal';
}
