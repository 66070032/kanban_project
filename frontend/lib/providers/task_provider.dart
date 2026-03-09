import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

/// Task Service Provider - Manages task API calls
class TaskService {
  static const String baseUrl = 'http://localhost:3000';

  /// Get all tasks for current user
  static Future<List<Task>> getUserTasks(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tasks/assignee/$userId'));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((task) => Task.fromJson(task)).toList();
      } else {
        throw Exception('Failed to load tasks: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  /// Get task by ID
  static Future<Task> getTaskById(int taskId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tasks/$taskId'));

      if (res.statusCode == 200) {
        return Task.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to load task: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching task: $e');
    }
  }

  /// Create new task
  static Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(taskData),
      );

      if (res.statusCode == 201) {
        return Task.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to create task: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  /// Update task
  static Future<Task> updateTask(
    int taskId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (res.statusCode == 200) {
        return Task.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to update task: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  /// Delete task
  static Future<void> deleteTask(int taskId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/tasks/$taskId'));

      if (res.statusCode != 200) {
        throw Exception('Failed to delete task: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  /// Upload voice instruction
  static Future<String> uploadVoiceInstruction(
    int taskId,
    String filePath,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/tasks/$taskId/voice-instruction'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('voice_instruction', filePath),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data['voice_instruction_url'] ?? '';
      } else {
        throw Exception('Failed to upload voice instruction');
      }
    } catch (e) {
      throw Exception('Error uploading voice instruction: $e');
    }
  }
}

/// Riverpod Provider for tasks list
final userTasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  userId,
) async {
  return TaskService.getUserTasks(userId);
});

/// Riverpod Provider for single task
final taskDetailProvider = FutureProvider.family<Task, int>((
  ref,
  taskId,
) async {
  return TaskService.getTaskById(taskId);
});

/// Riverpod Provider for creating task
final createTaskProvider = FutureProvider.family<Task, Map<String, dynamic>>((
  ref,
  taskData,
) async {
  return TaskService.createTask(taskData);
});

/// Riverpod Provider for updating task
final updateTaskProvider =
    FutureProvider.family<Task, (int, Map<String, dynamic>)>((
      ref,
      params,
    ) async {
      return TaskService.updateTask(params.$1, params.$2);
    });

/// Riverpod Provider for deleting task
final deleteTaskProvider = FutureProvider.family<void, int>((
  ref,
  taskId,
) async {
  return TaskService.deleteTask(taskId);
});

/// Riverpod Provider for uploading voice instruction
final uploadVoiceInstructionProvider =
    FutureProvider.family<String, (int, String)>((ref, params) async {
      return TaskService.uploadVoiceInstruction(params.$1, params.$2);
    });

/// NotifierProvider for task creation form state
class TaskFormNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {
      'title': '',
      'description': '',
      'status': 'todo',
      'dueAt': null,
      'voiceInstructionPath': null,
    };
  }

  void setTitle(String title) {
    state = {...state, 'title': title};
  }

  void setDescription(String description) {
    state = {...state, 'description': description};
  }

  void setStatus(String status) {
    state = {...state, 'status': status};
  }

  void setDueDate(DateTime? date) {
    state = {...state, 'dueAt': date};
  }

  void setVoiceInstruction(String? path) {
    state = {...state, 'voiceInstructionPath': path};
  }

  void reset() {
    state = {
      'title': '',
      'description': '',
      'status': 'todo',
      'dueAt': null,
      'voiceInstructionPath': null,
    };
  }
}

final taskFormProvider =
    NotifierProvider<TaskFormNotifier, Map<String, dynamic>>(
      TaskFormNotifier.new,
    );
