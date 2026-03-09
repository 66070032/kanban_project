import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/reminder_model.dart';
import '../core/config/app_config.dart';
import '../services/notification_service.dart';

/// Reminder Service Provider - Manages reminder API calls
class ReminderService {
  static String get baseUrl => AppConfig.baseUrl;

  /// Get all reminders for user
  static Future<List<Reminder>> getUserReminders(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reminders/user/$userId'));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((reminder) => Reminder.fromJson(reminder)).toList();
      } else {
        throw Exception('Failed to load reminders: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reminders: $e');
    }
  }

  /// Get reminder by ID
  static Future<Reminder> getReminderById(String reminderId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reminders/$reminderId'));

      if (res.statusCode == 200) {
        return Reminder.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to load reminder: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reminder: $e');
    }
  }

  /// Create new reminder
  static Future<Reminder> createReminder(
    Map<String, dynamic> reminderData,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reminders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reminderData),
      );

      if (res.statusCode == 201) {
        return Reminder.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to create reminder: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating reminder: $e');
    }
  }

  /// Update reminder
  static Future<Reminder> updateReminder(
    String reminderId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/reminders/$reminderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (res.statusCode == 200) {
        return Reminder.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to update reminder: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating reminder: $e');
    }
  }

  /// Delete reminder
  static Future<void> deleteReminder(String reminderId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/reminders/$reminderId'),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to delete reminder: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting reminder: $e');
    }
  }

  /// Upload voice reminder audio
  static Future<String> uploadVoiceReminder(
    String reminderId,
    String filePath,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/reminders/$reminderId/voice'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('voice_reminder', filePath),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data['voice_reminder_url'] ?? '';
      } else {
        throw Exception('Failed to upload voice reminder');
      }
    } catch (e) {
      throw Exception('Error uploading voice reminder: $e');
    }
  }
}

/// Riverpod Provider for reminders list.
/// Automatically schedules local notifications for upcoming reminders.
final userRemindersProvider = FutureProvider.family<List<Reminder>, String>((
  ref,
  userId,
) async {
  final reminders = await ReminderService.getUserReminders(userId);
  await NotificationService().scheduleReminders(reminders);
  return reminders;
});

/// Riverpod Provider for single reminder
final reminderDetailProvider = FutureProvider.family<Reminder, String>((
  ref,
  reminderId,
) async {
  return ReminderService.getReminderById(reminderId);
});

/// Riverpod Provider for creating reminder
final createReminderProvider =
    FutureProvider.family<Reminder, Map<String, dynamic>>((
      ref,
      reminderData,
    ) async {
      return ReminderService.createReminder(reminderData);
    });

/// Riverpod Provider for updating reminder
final updateReminderProvider =
    FutureProvider.family<Reminder, (String, Map<String, dynamic>)>((
      ref,
      params,
    ) async {
      return ReminderService.updateReminder(params.$1, params.$2);
    });

/// Riverpod Provider for deleting reminder
final deleteReminderProvider = FutureProvider.family<void, String>((
  ref,
  reminderId,
) async {
  return ReminderService.deleteReminder(reminderId);
});

/// Riverpod Provider for uploading voice reminder
final uploadVoiceReminderProvider =
    FutureProvider.family<String, (String, String)>((ref, params) async {
      return ReminderService.uploadVoiceReminder(params.$1, params.$2);
    });

/// NotifierProvider for voice notification state
class VoiceNotificationNotifier
    extends
        Notifier<
          ({
            bool showIncomingCall,
            String? callerId,
            String? callerName,
            String? taskTitle,
          })
        > {
  @override
  ({
    bool showIncomingCall,
    String? callerId,
    String? callerName,
    String? taskTitle,
  })
  build() {
    return (
      showIncomingCall: false,
      callerId: null,
      callerName: null,
      taskTitle: null,
    );
  }

  void showIncomingCallNotification({
    required String callerId,
    required String callerName,
    required String taskTitle,
  }) {
    state = (
      showIncomingCall: true,
      callerId: callerId,
      callerName: callerName,
      taskTitle: taskTitle,
    );
  }

  void hideIncomingCallNotification() {
    state = (
      showIncomingCall: false,
      callerId: null,
      callerName: null,
      taskTitle: null,
    );
  }
}

final voiceNotificationProvider =
    NotifierProvider<
      VoiceNotificationNotifier,
      ({
        bool showIncomingCall,
        String? callerId,
        String? callerName,
        String? taskTitle,
      })
    >(VoiceNotificationNotifier.new);
