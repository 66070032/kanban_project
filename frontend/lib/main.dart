import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'auth_gate.dart';
import 'services/notification_service.dart';
import 'services/background_sync_service.dart';
import 'features/task/widget/incoming_call_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().initialize();
  } catch (_) {}

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  BackgroundSyncService.initForegroundTask();

  // When a notification is tapped
  NotificationService.onNotificationTap = (payload) {
    // Only show incoming call screen for fake-call notifications
    // Payload format: "call:<taskTitle>\x1F<voiceUrl>" (voiceUrl may be empty)
    if (payload != null && payload.startsWith('call:')) {
      final data = payload.substring(5);
      final parts = data.split('\x1F');
      final taskTitle = parts[0];
      final voiceUrl = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1]
          : null;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callerId: 'reminder',
            callerName: 'Task Reminder',
            callerAvatarUrl: '',
            taskTitle: taskTitle.isNotEmpty
                ? taskTitle
                : 'You have a task reminder!',
            onAccept: () {},
            onReject: () {},
            voiceInstructionUrl: voiceUrl,
          ),
        ),
      );
    }
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
