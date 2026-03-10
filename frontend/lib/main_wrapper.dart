import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanban_project/features/profile/pages/profile_pages.dart';
import '../features/dashboard/widgets/dashboard_screen.dart';
import '../features/group/group_page.dart';
import '../features/calendar/pages/calendar_page.dart';
import 'misc/navigation.dart';
import 'services/notification_service.dart';
import 'services/background_sync_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _foregroundPollTimer;

  final List<Widget> _pages = [
    const DashboardPage(),
    const CalendarPage(),
    const GroupPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay permission request until after first frame to avoid UI freeze
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      try {
        await NotificationService().requestPermissions();
      } catch (_) {}
      // Handle notification that launched the app from terminated state
      try {
        await NotificationService().checkLaunchNotification();
      } catch (_) {}
    });
    _startForegroundPolling();
  }

  @override
  void dispose() {
    _foregroundPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground — poll immediately and restart timer
      _startForegroundPolling();
    } else if (state == AppLifecycleState.paused) {
      _foregroundPollTimer?.cancel();
    }
  }

  void _startForegroundPolling() {
    _foregroundPollTimer?.cancel();
    // Poll every 30 seconds while app is in foreground
    _foregroundPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollForUpdates(),
    );
    // Also poll immediately
    _pollForUpdates();
  }

  Future<void> _pollForUpdates() async {
    try {
      await BackgroundSyncService.runSync();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
