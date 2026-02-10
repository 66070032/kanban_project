import 'package:flutter/material.dart';
import 'package:kanban_project/features/profile/pages/profile_pages.dart';
import '../features/dashboard/widgets/dashboard_screen.dart';
import '../features/group/group_page.dart';
import 'misc/navigation.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // 1. Define your main pages here
  final List<Widget> _pages = [
    const DashboardPage(),
    const Center(child: Text("Calendar Page")),
    const GroupPage(),
    const ProfilePage(),
  ];

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
