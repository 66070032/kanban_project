import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task_model.dart';
import '../core/config/app_config.dart';
import 'auth_provider.dart';

/// Task Service Provider - Manages task API calls
class TaskService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<List<Task>> getUserTasks(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/tasks/assignee/$userId'))
          .timeout(const Duration(seconds: 10));

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
      print('DEBUG: Uploading voice for task $taskId from $filePath');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/tasks/$taskId/voice-instruction'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('voice_instruction', filePath),
      );

      print('DEBUG: Sending multipart request to ${request.url}');
      final response = await request.send();
      final body = await response.stream.bytesToString();

      print('DEBUG: Voice upload response code: ${response.statusCode}');
      print('DEBUG: Voice upload response body: $body');

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data['voice_instruction_url'] ?? '';
      } else {
        throw Exception(
          'Failed to upload voice instruction: ${response.statusCode} - $body',
        );
      }
    } catch (e) {
      throw Exception('Error uploading voice instruction: $e');
    }
  }
}

/// Riverpod Provider for tasks list (read-only fetch)
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

/// TasksNotifier — manages task mutations imperatively (create/update/delete).
/// Consumers call methods on the notifier; state holds the latest task list.
class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final user = ref.watch(authProvider);
    if (user == null) return [];
    return TaskService.getUserTasks(user.id);
  }

  Future<bool> createTask(Map<String, dynamic> taskData) async {
    try {
      final newTask = await TaskService.createTask(taskData);
      state = AsyncData([...state.asData?.value ?? [], newTask]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final updated = await TaskService.updateTask(taskId, updates);
      state = AsyncData(
        (state.asData?.value ?? [])
            .map((t) => t.id == taskId ? updated : t)
            .toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      await TaskService.deleteTask(taskId);
      state = AsyncData(
        (state.asData?.value ?? []).where((t) => t.id != taskId).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadVoiceInstruction(int taskId, String filePath) async {
    try {
      print(
        'DEBUG [TasksNotifier]: Calling uploadVoiceInstruction for task $taskId',
      );
      await TaskService.uploadVoiceInstruction(taskId, filePath);
      print('DEBUG [TasksNotifier]: Upload successful!');
      return true;
    } catch (e) {
      print('DEBUG [TasksNotifier]: Upload failed with error: $e');
      return false;
    }
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

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
