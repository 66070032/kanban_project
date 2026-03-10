import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/config/app_config.dart';
import 'error_handler_service.dart';

const _kLastReminderCheck = 'bg_last_reminder_check';
const _kKnownReminderIds = 'bg_known_reminder_ids';

/// Handles syncing and notifications for reminders in background
class ReminderSyncService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Sync reminders and show notifications for new ones
  static Future<void> syncReminders(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin plugin,
    String userId,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/reminders/user/$userId'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw ServerException(
          message: 'Failed to sync reminders: ${res.statusCode}',
          statusCode: res.statusCode,
        );
      }

      final List<dynamic> reminders = jsonDecode(res.body);
      final knownIds =
          prefs.getStringList(_kKnownReminderIds)?.toSet() ?? <String>{};
      final now = DateTime.now();

      for (final reminder in reminders) {
        try {
          final id = reminder['id']?.toString() ?? '';
          final title = reminder['title'] ?? 'Reminder';
          final description = reminder['description'] ?? '';
          final isCompleted = reminder['is_completed'] == true;
          final isSent = reminder['is_sent'] == true;
          final dueDateStr = reminder['due_date'];

          if (isCompleted || isSent) continue;

          // Notify about new reminders
          if (id.isNotEmpty && !knownIds.contains(id)) {
            await _showNotification(
              plugin,
              id: ('new_reminder_$id').hashCode.abs() % 100000 + 500000,
              channelId: 'kanban_reminders',
              channelName: 'Task Reminders',
              title: '\u{1F514} New Reminder',
              body: title,
            );
          }

          // Schedule future notifications
          if (dueDateStr != null) {
            final dueDate = DateTime.tryParse(dueDateStr);
            if (dueDate != null && dueDate.isAfter(now)) {
              final baseId = id.hashCode.abs() % 100000;

              await _scheduleNotification(
                plugin,
                id: baseId,
                channelId: 'kanban_reminders',
                channelName: 'Task Reminders',
                title: '\u{1F514} Reminder: $title',
                body: description.isNotEmpty
                    ? description
                    : 'You have a task reminder!',
                scheduledTime: dueDate,
              );

              final fiveMinBefore = dueDate.subtract(
                const Duration(minutes: 5),
              );
              if (fiveMinBefore.isAfter(now)) {
                await _scheduleCallNotification(
                  plugin,
                  id: baseId + 300000,
                  title: '\u{1F4DE} Incoming Call',
                  body: '$title \u2014 due in 5 minutes!',
                  scheduledTime: fiveMinBefore,
                  taskTitle: title,
                );
              }
            }
          }

          if (id.isNotEmpty) knownIds.add(id);
        } catch (e) {
          print('Error processing reminder: $e');
        }
      }

      await prefs.setStringList(_kKnownReminderIds, knownIds.toList());
      await prefs.setString(
        _kLastReminderCheck,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error syncing reminders: $e');
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
      payload: taskTitle != null ? 'call:$taskTitle\x1F' : null,
    );
  }
}
