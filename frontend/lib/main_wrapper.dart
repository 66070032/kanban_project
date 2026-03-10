import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanban_project/features/profile/pages/profile_pages.dart';
import '../features/dashboard/widgets/dashboard_screen.dart';
import '../features/group/group_page.dart';
import '../features/calendar/pages/calendar_page.dart';
import 'misc/navigation.dart';
import 'services/notification_service.dart';
import 'services/background_sync_service.dart';
import 'services/connectivity_service.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'features/task/widget/incoming_call_screen.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _foregroundPollTimer;
  Timer? _deadlineCheckTimer;
  bool _isOffline = false;
  StreamSubscription<bool>? _connectivitySub;
  final Set<int> _triggeredCallTaskIds = {};
  bool _isShowingCallScreen = false;

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

    // Initialize connectivity monitoring
    final connectivity = ConnectivityService();
    connectivity.initialize();
    _isOffline = !connectivity.isOnline;

    _connectivitySub = connectivity.connectionStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOffline = !isOnline);
      }
    });
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
    _startDeadlineChecker();
  }

  @override
  void dispose() {
    _foregroundPollTimer?.cancel();
    _deadlineCheckTimer?.cancel();
    _connectivitySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground — poll immediately and restart timer
      _startForegroundPolling();
      _startDeadlineChecker();
    } else if (state == AppLifecycleState.paused) {
      _foregroundPollTimer?.cancel();
      _deadlineCheckTimer?.cancel();
    }
  }

  /// Periodically checks if any task is approaching its deadline (within 5 min)
  /// and auto-shows the IncomingCallScreen with voice instruction playback.
  void _startDeadlineChecker() {
    _deadlineCheckTimer?.cancel();
    _deadlineCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkForUpcomingDeadlines(),
    );
  }

  Future<void> _checkForUpcomingDeadlines() async {
    if (_isShowingCallScreen) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    final tasksAsync = ref.read(userTasksProvider(user.id));
    final tasks = tasksAsync.asData?.value;
    if (tasks == null) return;

    final now = DateTime.now();
    for (final task in tasks) {
      if (task.dueAt == null) continue;
      if (task.status?.toLowerCase() == 'done') continue;
      if (_triggeredCallTaskIds.contains(task.id)) continue;

      final minutesUntilDue = task.dueAt!.difference(now).inMinutes;
      // Trigger when task is due within the next 5 minutes (but not past due)
      if (minutesUntilDue >= 0 && minutesUntilDue <= 5) {
        _triggeredCallTaskIds.add(task.id);
        _isShowingCallScreen = true;

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(
                callerId: 'deadline',
                callerName: 'Task Reminder',
                callerAvatarUrl: '',
                taskTitle: task.title,
                onAccept: () {},
                onReject: () {},
                voiceInstructionUrl: task.voiceInstructionUrl,
              ),
            ),
          );
          _isShowingCallScreen = false;
        }
        break; // Show one call at a time
      }
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
    // Skip polling when offline
    if (_isOffline) return;
    try {
      await BackgroundSyncService.runSync();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline banner
          if (_isOffline)
            Material(
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.orange[700],
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'No internet connection — Displaying recent data',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
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
