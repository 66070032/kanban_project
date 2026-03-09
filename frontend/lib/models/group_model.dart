class GroupModel {
  final int id;
  final String name;
  final String? description;
  final int? createdBy;
  final String? creatorName;
  final String? userRole;
  final int memberCount;
  final ChatMessage? lastMessage;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.createdBy,
    this.creatorName,
    this.userRole,
    this.memberCount = 0,
    this.lastMessage,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      createdBy: json['created_by'],
      creatorName: json['creator_name'],
      userRole: json['user_role'],
      memberCount: int.tryParse('${json['member_count']}') ?? 0,
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class ChatMessage {
  final int id;
  final int groupId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String messageType; // 'text' or 'task'
  final int? taskId;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.messageType = 'text',
    this.taskId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      groupId: json['group_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? 'Unknown',
      senderAvatar: json['sender_avatar'],
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      taskId: json['task_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class GroupMember {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.role = 'member',
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: '${json['id']}',
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
    );
  }
}
