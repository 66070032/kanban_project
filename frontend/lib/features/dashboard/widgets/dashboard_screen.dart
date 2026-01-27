import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'dashboard_header.dart';
import 'status_tabs.dart';
import 'upcoming_tasks.dart';
import 'stats.dart';
import 'navigation.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content
            const SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(),
                  SizedBox(height: 24),
                  StatusTabs(),
                  SizedBox(height: 24),
                  UpcomingTasksList(),
                  SizedBox(height: 24),
                  StatsGrid(),
                  SizedBox(height: 40),
                ],
              ),
            ),

            // Bottom Navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: const CustomBottomNavigation(),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: SizedBox(
          width: 64,
          height: 64,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppColors.cyan,
            elevation: 8,
            shape: const CircleBorder(),
            child: const Icon(Icons.mic, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
