import 'package:flutter/material.dart';
import 'status_tabs.dart';
import 'upcoming_tasks.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 16),
          StatusTabs(),
          SizedBox(height: 24),
          UpcomingTasksList(),
        ],
      ),
    );
  }
}