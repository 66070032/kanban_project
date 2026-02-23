import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'main_wrapper.dart'; // หรือหน้าหลักของคุณ

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const LoginPage();
    }

    return const MainWrapper(); // หน้า Home หลักของคุณ
  }
}