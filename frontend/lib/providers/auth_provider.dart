import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);