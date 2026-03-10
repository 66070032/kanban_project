import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import '../core/config/app_config.dart';

/// Keys
const _kUserId = 'bg_user_id';
const _kUserName = 'bg_user_name';
const _kLastMessageTs = 'bg_last_message_ts';
const _kLastReminderCheck = 'bg_last_reminder_check';
const _kLastTaskCheck = 'bg_last_task_check';
const _kKnownTaskIds = 'bg_known_task_ids';
const _kKnownReminderIds = 'bg_known_reminder_ids';

/// Work Manager task names
const backgroundSyncTask = 'com.kanban.backgroundSync';
const backgroundSyncTaskUnique = 'com.kanban.backgroundSync.periodic';

/// Top-level callback dispatcher — required by workmanager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await BackgroundSyncService.runSync();
      return true;
    } catch (e) {
      return false;
    }
  });
}

/// Persists user info so background tasks can access it.
class BackgroundSyncService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Save user session for background polling.
  static Future<void> saveUserSession(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kUserName, userName);
  }

  /// Clear session on logout.
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kLastMessageTs);
    await prefs.remove(_kLastReminderCheck);
    await prefs.remove(_kLastTaskCheck);
    await prefs.remove(_kKnownTaskIds);
    await prefs.remove(_kKnownReminderIds);
  }

  /// Register periodic background sync (every 15 min — Android minimum).
  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskUnique,
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Cancel all background tasks (call on logout).
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// The actual sync logic — runs in background isolate.
  static Future<void> runSync() async {
    tz_data.initializeTimeZones();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    if (userId == null) return; // Not logged in

    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(settings: initSettings);

    // Create channels
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'kanban_reminders',
        'Task Reminders',
        description: 'Notifications for task reminders and due dates',
        importance: Importance.high,
        playSound: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'kanban_fake_calls',
        'Fake Call Reminders',
        description: 'Incoming call-style reminders 5 minutes before deadlines',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'kanban_messages',
        'Group Messages',
        description: 'Notifications for new group messages',
        importance: Importance.high,
        playSound: true,
      ),
    );

    // ─── 1. Check for new tasks assigned to user ───
    await _syncTasks(prefs, plugin, userId);

    // ─── 2. Check for new reminders ───
    await _syncReminders(prefs, plugin, userId);

    // ─── 3. Check for new group messages ───
    await _syncGroupMessages(prefs, plugin, userId);
  }

  // ─── Task Sync ────────────────────────────────────────────────────────────────

  static Future<void> _syncTasks(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin plugin,
    String userId,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/tasks/assignee/$userId'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;

      final List<dynamic> tasks = jsonDecode(res.body);
      final knownIds =
          prefs.getStringList(_kKnownTaskIds)?.toSet() ?? <String>{};
      final now = DateTime.now();

      for (final task in tasks) {
        final id = task['id']?.toString() ?? '';
        final title = task['title'] ?? 'Untitled Task';
        final description = task['description'] ?? '';
        final status = task['status']?.toString().toLowerCase() ?? 'todo';
        final dueAtStr = task['due_at'];

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

        // Schedule 5-min-before call + at-deadline notification
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
              body: description.isNotEmpty ? description : 'Your task is due now!',
              scheduledTime: dueAt,
            );

            final fiveMinBefore =
                dueAt.subtract(const Duration(minutes: 5));
            if (fiveMinBefore.isAfter(now)) {
              await _scheduleCallNotification(
                plugin,
                id: baseId + 100000,
                title: '\u{1F4DE} Incoming Call',
                body: '$title \u2014 due in 5 minutes!',
                scheduledTime: fiveMinBefore,
              );
            }
          }
        }

        if (id.isNotEmpty) knownIds.add(id);
      }

      await prefs.setStringList(_kKnownTaskIds, knownIds.toList());
    } catch (_) {}
  }

  // ─── Reminder Sync ────────────────────────────────────────────────────────────

  static Future<void> _syncReminders(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin plugin,
    String userId,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/reminders/user/$userId'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;

      final List<dynamic> reminders = jsonDecode(res.body);
      final knownIds =
          prefs.getStringList(_kKnownReminderIds)?.toSet() ?? <String>{};
      final now = DateTime.now();

      for (final reminder in reminders) {
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

            final fiveMinBefore =
                dueDate.subtract(const Duration(minutes: 5));
            if (fiveMinBefore.isAfter(now)) {
              await _scheduleCallNotification(
                plugin,
                id: baseId + 300000,
                title: '\u{1F4DE} Incoming Call',
                body: '$title \u2014 due in 5 minutes!',
                scheduledTime: fiveMinBefore,
              );
            }
          }
        }

        if (id.isNotEmpty) knownIds.add(id);
      }

      await prefs.setStringList(_kKnownReminderIds, knownIds.toList());
    } catch (_) {}
  }

  // ─── Group Message Sync ───────────────────────────────────────────────────────

  static Future<void> _syncGroupMessages(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin plugin,
    String userId,
  ) async {
    try {
      // Get user's groups
      final groupsRes = await http
          .get(Uri.parse('$_baseUrl/groups/user/$userId'))
          .timeout(const Duration(seconds: 15));
      if (groupsRes.statusCode != 200) return;

      final List<dynamic> groups = jsonDecode(groupsRes.body);
      final lastCheckIso = prefs.getString(_kLastMessageTs);
      final lastCheck = lastCheckIso != null
          ? DateTime.tryParse(lastCheckIso) ??
              DateTime.now().subtract(const Duration(minutes: 15))
          : DateTime.now().subtract(const Duration(minutes: 15));
      final userName = prefs.getString(_kUserName) ?? '';

      for (final group in groups) {
        final groupId = group['id'];
        final groupName = group['name'] ?? 'Group';
        if (groupId == null) continue;

        try {
          final messagesRes = await http
              .get(Uri.parse('$_baseUrl/groups/$groupId/messages?limit=10'))
              .timeout(const Duration(seconds: 10));
          if (messagesRes.statusCode != 200) continue;

          final List<dynamic> messages = jsonDecode(messagesRes.body);

          for (final msg in messages) {
            final senderId = msg['sender_id']?.toString() ?? '';
            final senderName = msg['sender_name'] ?? 'Someone';
            final content = msg['content'] ?? '';
            final messageType = msg['message_type'] ?? 'text';
            final createdAtStr = msg['created_at'];

            // Skip own messages
            if (senderId == userId) continue;

            // Only notify for messages newer than last check
            if (createdAtStr != null) {
              final createdAt = DateTime.tryParse(createdAtStr);
              if (createdAt != null && createdAt.isAfter(lastCheck)) {
                final notifId =
                    ('msg_${msg['id']}').hashCode.abs() % 100000 + 600000;

                if (messageType == 'task') {
                  await _showNotification(
                    plugin,
                    id: notifId,
                    channelId: 'kanban_messages',
                    channelName: 'Group Messages',
                    title: '\u{1F4CB} New Task in $groupName',
                    body: '$senderName assigned a task: $content',
                  );
                } else {
                  await _showNotification(
                    plugin,
                    id: notifId,
                    channelId: 'kanban_messages',
                    channelName: 'Group Messages',
                    title: '\u{1F4AC} $groupName',
                    body: '$senderName: $content',
                  );
                }
              }
            }
          }
        } catch (_) {}
      }

      await prefs.setString(_kLastMessageTs, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  // ─── Notification Helpers ─────────────────────────────────────────────────────

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
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          autoCancel: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
    );
  }
}
