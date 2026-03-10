import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task_model.dart';
import '../../task/pages/task_detail.dart';
import 'task_card.dart';

class UpcomingTasksList extends ConsumerWidget {
  final String statusFilter;

  const UpcomingTasksList({super.key, this.statusFilter = 'todo'});

  static const _statusMeta = {
    'todo': {
      'label': 'To Do',
      'color': AppColors.redTagText,
      'bg': AppColors.redTagBg,
      'icon': Icons.radio_button_unchecked,
    },
    'doing': {
      'label': 'In Progress',
      'color': AppColors.blueTagText,
      'bg': AppColors.blueTagBg,
      'icon': Icons.autorenew_rounded,
    },
    'done': {
      'label': 'Done',
      'color': AppColors.greenTagText,
      'bg': AppColors.greenTagBg,
      'icon': Icons.check_circle_outline_rounded,
    },
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue<List<Task>>.loading();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  'Please log in to view tasks.',
                  style: TextStyle(color: AppColors.subText),
                ),
              ),
            )
          else
            tasksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.cyan),
                ),
              ),
              error: (_, __) => _buildEmptyState(statusFilter),
              data: (allTasks) {
                // Filter by current status tab
                final filtered = allTasks
                    .where((t) => (t.status ?? 'todo') == statusFilter)
                    .toList();

                // Sort: tasks with due dates first (soonest first), then no due date
                filtered.sort((a, b) {
                  if (a.dueAt != null && b.dueAt != null) {
                    return a.dueAt!.compareTo(b.dueAt!);
                  } else if (a.dueAt != null) {
                    return -1;
                  } else if (b.dueAt != null) {
                    return 1;
                  }
                  return a.id.compareTo(b.id);
                });

                if (filtered.isEmpty) {
                  return _buildEmptyState(statusFilter);
                }

                return Column(
                  children: filtered.map<Widget>((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: TaskCard(
                        task: task,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailPage(task: task),
                            ),
                          );
                          ref.invalidate(userTasksProvider(user.id));
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    final meta = _statusMeta[status];
    final color = meta?['color'] as Color? ?? AppColors.cyan;
    final icon = meta?['icon'] as IconData? ?? Icons.task_alt;
    final label = meta?['label'] as String? ?? status;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              'No "$label" tasks',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to add a new task',
              style: TextStyle(color: AppColors.subText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
