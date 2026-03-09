import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '/misc/header.dart';
import 'status_tabs.dart';
import 'upcoming_tasks.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../task/pages/task_screen.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.grey[50],
      child: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.cyan,
              onRefresh: () async {
                final user = ref.read(authProvider);
                if (user != null) {
                  ref.invalidate(userTasksProvider(user.id));

                  try {
                    await ref.read(userTasksProvider(user.id).future);
                  } catch (_) {}
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    // StatsGrid(),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TaskScreen()),
                    );
                    // Refresh task list after returning
                    final user = ref.read(authProvider);
                    if (user != null) {
                      ref.invalidate(userTasksProvider(user.id));
                    }
                  },
                  backgroundColor: Colors.cyan,
                  elevation: 8,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
