import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/config/app_config.dart';
import 'error_handler_service.dart';

const _kLastTaskCheck = 'bg_last_task_check';
const _kKnownTaskIds = 'bg_known_task_ids';

/// Handles syncing and notifications for tasks in background
class TaskSyncService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Sync tasks and show notifications for new ones
  static Future<void> syncTasks(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin plugin,
    String userId,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/tasks/assignee/$userId'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw ServerException(
          message: 'Failed to sync tasks: ${res.statusCode}',
          statusCode: res.statusCode,
        );
      }

      final List<dynamic> tasks = jsonDecode(res.body);
      final knownIds =
          prefs.getStringList(_kKnownTaskIds)?.toSet() ?? <String>{};
      final now = DateTime.now();

      for (final task in tasks) {
        try {
          final id = task['id']?.toString() ?? '';
          final title = task['title'] ?? 'Untitled Task';
          final description = task['description'] ?? '';
          final status = task['status']?.toString().toLowerCase() ?? 'todo';
          final dueAtStr = task['due_at'];
          final voiceUuid = task['voice_instruction_uuid']?.toString();

          // Notify about new tasks (not known before)
          if (id.isNotEmpty && !knownIds.contains(id) && status != 'done') {
            await _showNotification(
              plugin,
              id: ('new_task_$id').hashCode.abs() % 100000 + 400000,
              channelId: 'kanban_reminders',
              channelName: 'Task Reminders',
              title: '\u{1F4CB} New Task Assigned',
              body: title,
            );
          }

          // Schedule notifications for due dates
          if (dueAtStr != null && status != 'done') {
            final dueAt = DateTime.tryParse(dueAtStr);
            if (dueAt != null && dueAt.isAfter(now)) {
              final taskIdNum = int.tryParse(id) ?? id.hashCode.abs();
              final baseId = taskIdNum.abs() % 100000 + 100000;

              await _scheduleNotification(
                plugin,
                id: baseId,
                channelId: 'kanban_reminders',
                channelName: 'Task Reminders',
                title: '\u23F0 Task Due: $title',
                body: description.isNotEmpty
                    ? description
                    : 'Your task is due now!',
                scheduledTime: dueAt,
              );

              final fiveMinBefore = dueAt.subtract(const Duration(minutes: 5));
              if (fiveMinBefore.isAfter(now)) {
                // Build voice instruction URL if UUID exists
                final voiceUrl = voiceUuid != null && voiceUuid.isNotEmpty
                    ? '$_baseUrl/uploads/$voiceUuid'
                    : '';
                await _scheduleCallNotification(
                  plugin,
                  id: baseId + 100000,
                  title: '\u{1F4DE} Incoming Call',
                  body: '$title \u2014 due in 5 minutes!',
                  scheduledTime: fiveMinBefore,
                  taskTitle: title,
                  voiceUrl: voiceUrl,
                );
              }
            }
          }

          if (id.isNotEmpty) knownIds.add(id);
        } catch (e) {
          print('Error processing task: $e');
        }
      }

      await prefs.setStringList(_kKnownTaskIds, knownIds.toList());
      await prefs.setString(_kLastTaskCheck, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error syncing tasks: $e');
    }
  }

  static Future<void> _showNotification(
    FlutterLocalNotificationsPlugin plugin, {
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
  }) async {
    await plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> _scheduleNotification(
    FlutterLocalNotificationsPlugin plugin, {
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    await plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  static Future<void> _scheduleCallNotification(
    FlutterLocalNotificationsPlugin plugin, {
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? taskTitle,
    String? voiceUrl,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    await plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'kanban_fake_calls',
          'Fake Call Reminders',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          autoCancel: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: taskTitle != null
          ? 'call:$taskTitle\x1F${voiceUrl ?? ''}'
          : null,
    );
  }
}
