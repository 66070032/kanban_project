import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder_model.dart';
import '../models/task_model.dart';

/// Background notification tap handler — must be top-level.
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Runs in a separate isolate; the app will pick up launch details on restart.
}

/// Notification Service using flutter_local_notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Standard reminder channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kanban_reminders',
    'Task Reminders',
    description: 'Notifications for task reminders and due dates',
    importance: Importance.high,
    playSound: true,
  );

  // Incoming-call-style channel (max priority, full-screen intent)
  static const AndroidNotificationChannel _callChannel =
      AndroidNotificationChannel(
        'kanban_fake_calls',
        'Fake Call Reminders',
        description: 'Incoming call-style reminders 5 minutes before deadlines',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  // Set this callback in main.dart to handle notification taps
  static void Function(String? payload)? onNotificationTap;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_callChannel);
  }

  /// Call after navigation is ready to handle a notification that launched the app.
  Future<void> checkLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      onNotificationTap?.call(details!.notificationResponse?.payload);
    }
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedule a standard notification at [scheduledTime].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Schedule an incoming-call-style notification (full-screen, max priority).
  Future<void> _scheduleCallNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _callChannel.id,
          _callChannel.name,
          channelDescription: _callChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Schedule notifications for each pending reminder:
  /// • At the due date
  /// • 5 minutes before the due date (incoming call style)
  Future<void> scheduleReminders(List<Reminder> reminders) async {
    final now = DateTime.now();
    for (final reminder in reminders) {
      if (reminder.isCompleted || reminder.isSent) continue;
      if (reminder.dueDate.isBefore(now)) continue;

      final baseId = reminder.id.hashCode.abs() % 100000;

      // At-deadline notification
      await scheduleNotification(
        id: baseId,
        title: '\u{1F514} Reminder: ${reminder.title}',
        body: reminder.description ?? 'You have a task reminder!',
        scheduledTime: reminder.dueDate,
        payload: reminder.title,
      );

      // 5-minute-before incoming-call notification
      final fiveMinBefore = reminder.dueDate.subtract(
        const Duration(minutes: 5),
      );
      if (fiveMinBefore.isAfter(now)) {
        await _scheduleCallNotification(
          id: baseId + 300000,
          title: '\u{1F4DE} Incoming Call',
          body: '${reminder.title} \u2014 due in 5 minutes!',
          scheduledTime: fiveMinBefore,
          payload: 'call:${reminder.title}',
        );
      }
    }
  }

  /// Schedule notifications for tasks that have a due date:
  /// • At the due date
  /// • 5 minutes before the due date (incoming call style)
  Future<void> scheduleTaskNotifications(List<Task> tasks) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.dueAt == null) continue;
      if (task.status?.toLowerCase() == 'done') continue;
      if (task.dueAt!.isBefore(now)) continue;

      final baseId = task.id.abs() % 100000 + 100000;

      // At-deadline notification
      await scheduleNotification(
        id: baseId,
        title: '\u23F0 Task Due: ${task.title}',
        body: task.description ?? 'Your task is due now!',
        scheduledTime: task.dueAt!,
        payload: task.title,
      );

      // 5-minute-before incoming-call notification
      final fiveMinBefore = task.dueAt!.subtract(const Duration(minutes: 5));
      if (fiveMinBefore.isAfter(now)) {
        await _scheduleCallNotification(
          id: baseId + 100000, // 200000+ range
          title: '\u{1F4DE} Incoming Call',
          body: '${task.title} \u2014 due in 5 minutes!',
          scheduledTime: fiveMinBefore,
          payload: 'call:${task.title}',
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async => _plugin.cancel(id: id);

  Future<void> cancelAll() async => _plugin.cancelAll();
}
