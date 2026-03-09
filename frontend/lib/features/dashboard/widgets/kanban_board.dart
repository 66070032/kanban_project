import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task_model.dart';
import '../../task/pages/task_detail.dart';

/// Kanban board view grouping tasks by status columns.
class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key});

  static const _columns = [
    {'status': 'todo', 'label': 'To Do', 'color': Colors.grey},
    {'status': 'doing', 'label': 'In Progress', 'color': Colors.orange},
    {'status': 'done', 'label': 'Done', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue<List<Task>>.data([]);

    return tasksAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load tasks: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (user != null) ref.invalidate(userTasksProvider(user.id));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (tasks) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _columns.map((col) {
            final status = col['status'] as String;
            final label = col['label'] as String;
            final color = col['color'] as Color;
            final colTasks = tasks
                .where((t) => (t.status ?? 'todo') == status)
                .toList();

            return _KanbanColumn(
              status: status,
              label: label,
              color: color,
              tasks: colTasks,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final String label;
  final Color color;
  final List<Task> tasks;

  const _KanbanColumn({
    required this.status,
    required this.label,
    required this.color,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color == Colors.grey ? Colors.black54 : color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Task cards
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'No tasks',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...tasks.map(
              (task) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
                ),
                child: _KanbanCard(task: task, accentColor: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Task task;
  final Color accentColor;

  const _KanbanCard({required this.task, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (task.dueAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${task.dueAt!.day}/${task.dueAt!.month}/${task.dueAt!.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
