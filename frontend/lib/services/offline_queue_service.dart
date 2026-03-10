import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents an offline operation to be synced later
class OfflineOperation {
  final String id;
  final String operationType; // 'create', 'update', 'delete'
  final String entityType; // 'task', 'reminder', 'group', etc.
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType,
      'entityType': entityType,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] as String,
      operationType: json['operationType'] as String,
      entityType: json['entityType'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// Manages offline operations queue for sync when connection is restored
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  static const String _queueKey = 'offline_queue';
  static const int _maxRetries = 3;

  factory OfflineQueueService() {
    return _instance;
  }

  OfflineQueueService._internal();

  /// Add operation to offline queue
  Future<void> addOperation(OfflineOperation operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await getQueue();

      queue.add(operation);

      final jsonList = queue.map((op) => jsonEncode(op.toJson())).toList();

      await prefs.setStringList(_queueKey, jsonList);
    } catch (e) {
      // Log silently - we'll try again
      print('Error adding to offline queue: $e');
    }
  }

  /// Get all pending operations
  Future<List<OfflineOperation>> getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_queueKey) ?? [];

      return jsonList
          .map((json) => OfflineOperation.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error reading offline queue: $e');
      return [];
    }
  }

  /// Remove operation from queue
  Future<void> removeOperation(String operationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await getQueue();

      queue.removeWhere((op) => op.id == operationId);

      final jsonList = queue.map((op) => jsonEncode(op.toJson())).toList();

      await prefs.setStringList(_queueKey, jsonList);
    } catch (e) {
      print('Error removing from offline queue: $e');
    }
  }

  /// Update operation's retry count
  Future<void> incrementRetryCount(String operationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await getQueue();

      final index = queue.indexWhere((op) => op.id == operationId);
      if (index != -1) {
        final operation = queue[index];
        queue[index] = OfflineOperation(
          id: operation.id,
          operationType: operation.operationType,
          entityType: operation.entityType,
          data: operation.data,
          createdAt: operation.createdAt,
          retryCount: operation.retryCount + 1,
        );
      }

      final jsonList = queue.map((op) => jsonEncode(op.toJson())).toList();

      await prefs.setStringList(_queueKey, jsonList);
    } catch (e) {
      print('Error updating retry count: $e');
    }
  }

  /// Check if an operation has exceeded max retries
  bool hasExceededMaxRetries(OfflineOperation operation) {
    return operation.retryCount >= _maxRetries;
  }

  /// Clear all operations from queue
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
    } catch (e) {
      print('Error clearing offline queue: $e');
    }
  }

  /// Get count of pending operations
  Future<int> getQueueLength() async {
    final queue = await getQueue();
    return queue.length;
  }

  /// Get pending tasks
  Future<List<OfflineOperation>> getPendingTasks() async {
    final queue = await getQueue();
    return queue.where((op) => op.entityType == 'task').toList();
  }

  /// Get pending reminders
  Future<List<OfflineOperation>> getPendingReminders() async {
    final queue = await getQueue();
    return queue.where((op) => op.entityType == 'reminder').toList();
  }

  /// Get operations that can be retried
  Future<List<OfflineOperation>> getRetryableOperations() async {
    final queue = await getQueue();
    return queue.where((op) => !hasExceededMaxRetries(op)).toList();
  }
}
