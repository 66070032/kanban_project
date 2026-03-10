import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import 'error_handler_service.dart';

const _kLastMessageTs = 'bg_last_message_ts';

/// Handles syncing and notifications for group messages in background
class MessageSyncService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Sync group messages and show notifications for new ones
  static Future<void> syncGroupMessages(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin plugin,
    String userId,
  ) async {
    try {
      // Get user's groups
      final groupsRes = await http
          .get(Uri.parse('$_baseUrl/groups/user/$userId'))
          .timeout(const Duration(seconds: 15));

      if (groupsRes.statusCode != 200) {
        throw ServerException(
          message: 'Failed to sync groups: ${groupsRes.statusCode}',
          statusCode: groupsRes.statusCode,
        );
      }

      final List<dynamic> groups = jsonDecode(groupsRes.body);
      final lastCheckIso = prefs.getString(_kLastMessageTs);
      final lastCheck = lastCheckIso != null
          ? DateTime.tryParse(lastCheckIso) ??
                DateTime.now().subtract(const Duration(minutes: 15))
          : DateTime.now().subtract(const Duration(minutes: 15));

      for (final group in groups) {
        try {
          final groupId = group['id'];
          final groupName = group['name'] ?? 'Group';
          if (groupId == null) continue;

          final messagesRes = await http
              .get(Uri.parse('$_baseUrl/groups/$groupId/messages?limit=10'))
              .timeout(const Duration(seconds: 10));

          if (messagesRes.statusCode != 200) continue;

          final List<dynamic> messages = jsonDecode(messagesRes.body);

          for (final msg in messages) {
            try {
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
            } catch (e) {
              print('Error processing message: $e');
            }
          }
        } catch (e) {
          print('Error syncing group messages: $e');
        }
      }

      await prefs.setString(_kLastMessageTs, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error syncing group messages: $e');
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
}
