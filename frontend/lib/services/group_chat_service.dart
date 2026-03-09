import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/app_config.dart';
import '../models/group_model.dart';
import '../models/task_model.dart';

class GroupChatService {
  static String get baseUrl => AppConfig.baseUrl;

  // ─── Groups ───

  static Future<List<GroupModel>> getUserGroups(String userId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/groups/user/$userId'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((g) => GroupModel.fromJson(g)).toList();
    } else {
      throw Exception('Failed to load groups: ${res.statusCode}');
    }
  }

  static Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String createdBy,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'created_by': createdBy,
      }),
    );

    if (res.statusCode == 201) {
      return GroupModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to create group: ${res.statusCode}');
    }
  }

  static Future<void> deleteGroup(int groupId) async {
    final res = await http.delete(Uri.parse('$baseUrl/groups/$groupId'));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete group: ${res.statusCode}');
    }
  }

  // ─── Members ───

  static Future<List<GroupMember>> getGroupMembers(int groupId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/groups/$groupId/members'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((m) => GroupMember.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load members: ${res.statusCode}');
    }
  }

  static Future<void> addMember(int groupId, String userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (res.statusCode != 201) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Failed to add member');
    }
  }

  static Future<void> removeMember(int groupId, String userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to remove member: ${res.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers(
    int groupId,
    String query,
  ) async {
    final res = await http
        .get(Uri.parse('$baseUrl/groups/$groupId/search-users?q=$query'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception('Failed to search users: ${res.statusCode}');
    }
  }

  // ─── Messages ───

  static Future<List<ChatMessage>> getMessages(
    int groupId, {
    int? before,
    int limit = 50,
  }) async {
    String url = '$baseUrl/groups/$groupId/messages?limit=$limit';
    if (before != null) {
      url += '&before=$before';
    }

    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((m) => ChatMessage.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load messages: ${res.statusCode}');
    }
  }

  static Future<ChatMessage> sendMessage({
    required int groupId,
    required String senderId,
    required String content,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sender_id': senderId, 'content': content}),
    );

    if (res.statusCode == 201) {
      return ChatMessage.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to send message: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> sendTaskMessage({
    required int groupId,
    required String senderId,
    required String title,
    String? description,
    String? assigneeId,
    String? dueAt,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/messages/task'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': senderId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'due_at': dueAt,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to create task: ${res.statusCode}');
    }
  }

  // ─── Group Tasks ───

  static Future<List<Task>> getGroupTasks(int groupId) async {
    try {
      // Try dedicated group tasks endpoint first
      final res = await http
          .get(Uri.parse('$baseUrl/tasks/group/$groupId'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((t) => Task.fromJson(t)).toList();
      }

      // Fallback: fetch all tasks and filter by group_id
      if (res.statusCode == 404) {
        return _getGroupTasksFallback(groupId);
      }

      throw Exception('Failed to load group tasks: ${res.statusCode}');
    } catch (e) {
      if (e.toString().contains('Failed to load group tasks')) rethrow;
      // Network error / timeout → try fallback
      return _getGroupTasksFallback(groupId);
    }
  }

  static Future<List<Task>> _getGroupTasksFallback(int groupId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/tasks'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .where((t) => t['group_id'] == groupId)
          .map((t) => Task.fromJson(t))
          .toList();
    } else {
      throw Exception('Failed to load group tasks: ${res.statusCode}');
    }
  }
}
