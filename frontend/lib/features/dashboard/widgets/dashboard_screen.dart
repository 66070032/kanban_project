import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '/misc/header.dart';
import 'status_tabs.dart';
import 'upcoming_tasks.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../task/pages/task_screen.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _selectedStatus = 'todo';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGray,
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
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Header(),
                    const SizedBox(height: 8),
                    StatusTabs(
                      selectedStatus: _selectedStatus,
                      onStatusChanged: (status) {
                        setState(() => _selectedStatus = status);
                      },
                    ),
                    const SizedBox(height: 20),
                    UpcomingTasksList(statusFilter: _selectedStatus),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaskScreen()),
                  );
                  final user = ref.read(authProvider);
                  if (user != null) {
                    ref.invalidate(userTasksProvider(user.id));
                  }
                },
                backgroundColor: AppColors.cyan,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
