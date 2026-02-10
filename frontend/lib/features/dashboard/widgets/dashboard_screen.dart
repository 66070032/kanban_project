import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '/misc/navigation.dart';
import '/misc/header.dart';
import 'status_tabs.dart';
import 'upcoming_tasks.dart';
import 'stats.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Header(),
              SizedBox(height: 24),
              StatusTabs(),
              SizedBox(height: 24),
              UpcomingTasksList(),
              SizedBox(height: 24),
              StatsGrid(),
              SizedBox(
                height: 80,
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.cyan,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.mic, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
