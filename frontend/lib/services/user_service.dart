import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../core/config/app_config.dart';

class UserService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<User> updateUser(
    String id, {
    required String displayName,
    String? avatarUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'displayName': displayName, 'avatarUrl': avatarUrl}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update user');
    }
    return User.fromJson(jsonDecode(response.body));
  }

  /// Reads [filePath] as bytes, base64-encodes it, and saves via the
  /// existing PUT /users/:id endpoint — no new backend endpoint required.
  static Future<User> uploadAvatar(
    String id,
    String filePath, {
    required String displayName,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final ext = filePath.toLowerCase();
    final mime = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    return updateUser(id, displayName: displayName, avatarUrl: dataUrl);
  }

  static Future<void> changePassword(
    String id, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to change password');
    }
  }
}
