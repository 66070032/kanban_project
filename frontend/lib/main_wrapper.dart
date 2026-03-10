import 'package:flutter/material.dart';
import 'package:kanban_project/features/profile/pages/profile_pages.dart';
import '../features/dashboard/widgets/dashboard_screen.dart';
import '../features/group/group_page.dart';
import '../features/calendar/pages/calendar_page.dart';
import 'misc/navigation.dart';
import 'services/notification_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const CalendarPage(),
    const GroupPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
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
