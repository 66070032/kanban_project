import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:workmanager/workmanager.dart';
import 'task_sync_service.dart';
import 'reminder_sync_service.dart';
import 'message_sync_service.dart';

/// Keys
const _kUserId = 'bg_user_id';
const _kUserName = 'bg_user_name';

/// Work Manager task names
const backgroundSyncTask = 'com.kanban.backgroundSync';
const backgroundSyncTaskUnique = 'com.kanban.backgroundSync.periodic';

/// Top-level callback dispatcher — required by workmanager (fallback).
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

/// Top-level entry point for the foreground service isolate.
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(SyncTaskHandler());
}

/// Foreground service task handler — polls every 30 seconds.
class SyncTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // First sync immediately when service starts
    await BackgroundSyncService.runSync();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    await BackgroundSyncService.runSync();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Persists user info so background tasks can access it.
class BackgroundSyncService {
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

  /// Initialize the foreground task configuration (call once in main).
  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kanban_foreground_service',
        channelName: 'Kanban Sync Service',
        channelDescription: 'Keeps checking for new tasks and messages',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000), // 30 seconds
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start the foreground service (call after login / session restore).
  static Future<void> startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Kanban',
      notificationText: 'Checking for new tasks and messages',
      callback: startForegroundCallback,
    );
  }

  /// Stop the foreground service (call on logout).
  static Future<void> stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }

  /// Check if device has internet
  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// The actual sync logic — runs in background isolate.
  /// Delegates to specialized sync services to keep code modular.
  static Future<void> runSync() async {
    // Skip sync if offline
    if (!await _hasInternet()) return;

    tz_data.initializeTimeZones();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    if (userId == null) return; // Not logged in

    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(settings: initSettings);

    // Create notification channels
    await _createNotificationChannels(plugin);

    // Delegate to specialized sync services
    try {
      await TaskSyncService.syncTasks(prefs, plugin, userId);
    } catch (e) {
      print('Task sync error: $e');
    }

    try {
      await ReminderSyncService.syncReminders(prefs, plugin, userId);
    } catch (e) {
      print('Reminder sync error: $e');
    }

    try {
      await MessageSyncService.syncGroupMessages(prefs, plugin, userId);
    } catch (e) {
      print('Message sync error: $e');
    }
  }

  /// Create all notification channels for Android
  static Future<void> _createNotificationChannels(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

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
  }
}
