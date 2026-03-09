import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task_model.dart';
import '../../task/pages/task_detail.dart';
import '../../task/pages/task_screen.dart';

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
                      child: _TaskCard(
                        task: task,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailPage(task: task),
                            ),
                          );
                          if (user != null) {
                            ref.invalidate(userTasksProvider(user.id));
                          }
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

//  Task Card

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  static const _statusMeta = {
    'todo': {
      'label': 'To Do',
      'color': AppColors.redTagText,
      'bg': AppColors.redTagBg,
    },
    'doing': {
      'label': 'In Progress',
      'color': AppColors.blueTagText,
      'bg': AppColors.blueTagBg,
    },
    'done': {
      'label': 'Done',
      'color': AppColors.greenTagText,
      'bg': AppColors.greenTagBg,
    },
  };

  @override
  Widget build(BuildContext context) {
    final status = task.status ?? 'todo';
    final meta = _statusMeta[status] ?? _statusMeta['todo']!;
    final statusColor = meta['color'] as Color;
    final statusBg = meta['bg'] as Color;
    final statusLabel = meta['label'] as String;

    final bool isOverdue =
        task.dueAt != null &&
        task.dueAt!.isBefore(DateTime.now()) &&
        status != 'done';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: status badge + time badge
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Due date badge
                if (task.dueAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? const Color(0xFFFFEEEE)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: isOverdue ? Colors.red : AppColors.subText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task.dueAt),
                          style: TextStyle(
                            color: isOverdue ? Colors.red : AppColors.subText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'No Due Date',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              task.title,
              style: TextStyle(
                color: status == 'done' ? AppColors.subText : AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: status == 'done'
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppColors.subText,
              ),
            ),

            // Description
            if ((task.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Bottom row: avatar initials + arrow
            Row(
              children: [
                // Avatar initial circle
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    task.title.isNotEmpty ? task.title[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Personal',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No Due Date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    int hour = date.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final timeStr = '$hour:${date.minute.toString().padLeft(2, '0')} $period';

    if (dateOnly == today) return 'Today  $timeStr';
    if (dateOnly == tomorrow) return 'Tomorrow  $timeStr';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}  $timeStr';
  }
}

//  All Tasks Page (See All)

class _AllTasksPage extends ConsumerWidget {
  const _AllTasksPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue<List<Task>>.data([]);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.cyan,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskScreen()),
            ),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (_, __) => const Center(child: Text('Failed to load tasks.')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No tasks yet. Tap + to add one!',
                style: TextStyle(color: AppColors.subText),
              ),
            );
          }
          final sorted = [...tasks]
            ..sort((a, b) {
              if (a.dueAt != null && b.dueAt != null) {
                return a.dueAt!.compareTo(b.dueAt!);
              } else if (a.dueAt != null) {
                return -1;
              } else if (b.dueAt != null) {
                return 1;
              }
              return a.id.compareTo(b.id);
            });
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TaskCard(
                task: sorted[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailPage(task: sorted[index]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
