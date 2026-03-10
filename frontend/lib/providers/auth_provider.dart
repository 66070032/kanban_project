import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

const _kUserSession = 'saved_user_session';

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User user) {
    state = user;
    _persistUser(user);
  }

  void logout() {
    state = null;
    _clearPersistedUser();
  }

  /// Restore user from SharedPreferences (call on app start).
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kUserSession);
    if (json != null) {
      try {
        final user = User.fromJson(jsonDecode(json));
        state = user;
        return true;
      } catch (_) {
        await prefs.remove(_kUserSession);
      }
    }
    return false;
  }

  Future<void> _persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserSession, jsonEncode(user.toJson()));
  }

  Future<void> _clearPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserSession);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);