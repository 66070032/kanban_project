import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_gate.dart';
import 'services/notification_service.dart';
import 'features/task/widget/incoming_call_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().initialize();
  } catch (_) {
    // Notifications unavailable on this platform/emulator configuration
  }

  // When a reminder notification is tapped → open the incoming call screen
  NotificationService.onNotificationTap = (payload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerId: 'reminder',
          callerName: 'Task Reminder',
          callerAvatarUrl: '',
          taskTitle: payload ?? 'You have a task reminder!',
          onAccept: () => navigatorKey.currentState?.pop(),
          onReject: () => navigatorKey.currentState?.pop(),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanban App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
      ),
      home: const AuthGate(),
    );
  }
}
