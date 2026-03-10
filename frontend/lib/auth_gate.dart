import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'main_wrapper.dart';
import 'services/background_sync_service.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final restored = await ref.read(authProvider.notifier).restoreSession();
    if (restored) {
      // Re-register background sync for the restored session
      final user = ref.read(authProvider);
      if (user != null) {
        await BackgroundSyncService.saveUserSession(user.id, user.displayName);
        await BackgroundSyncService.registerPeriodicSync();
        BackgroundSyncService.runSync();
      }
    }
    if (mounted) setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = ref.watch(authProvider);
    if (user == null) {
      return const LoginPage();
    }
    return const MainWrapper();
  }
}