import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../task/pages/task_detail.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'doing':
        return Colors.orange;
      default:
        return AppColors.cyan;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'done':
        return 'Done';
      case 'doing':
        return 'Doing';
      default:
        return 'Todo';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue<List<Task>>.data([]);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: tasksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (e, _) => Center(child: Text('Error loading tasks: $e')),
        data: _buildBody,
      ),
    );
  }

  Widget _buildBody(List<Task> tasks) {
    // Group tasks by their due date key
    final Map<String, List<Task>> tasksByDay = {};
    for (final task in tasks) {
      if (task.dueAt != null) {
        tasksByDay.putIfAbsent(_dateKey(task.dueAt!), () => []).add(task);
      }
    }

    final selectedTasks = _selectedDay != null
        ? (tasksByDay[_dateKey(_selectedDay!)] ?? [])
        : <Task>[];

    return Column(
      children: [
        // ── Month navigation ──
        _MonthHeader(
          focusedMonth: _focusedMonth,
          onPrev: () => setState(
            () => _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month - 1,
            ),
          ),
          onNext: () => setState(
            () => _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
            ),
          ),
        ),
        // ── Weekday labels ──
        const _WeekdayLabels(),
        // ── Calendar grid ──
        _CalendarGrid(
          focusedMonth: _focusedMonth,
          selectedDay: _selectedDay,
          tasksByDay: tasksByDay,
          onDayTap: (d) => setState(() => _selectedDay = d),
          statusColor: _statusColor,
          dateKey: _dateKey,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        // ── Task list for selected day ──
        Expanded(child: _buildDayTaskList(selectedTasks)),
      ],
    );
  }

  Widget _buildDayTaskList(List<Task> tasks) {
    final label = _selectedDay != null
        ? DateFormat('EEEE, MMMM d').format(_selectedDay!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              if (tasks.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (tasks.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 52,
                    color: AppColors.subText,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No tasks due this day',
                    style: TextStyle(color: AppColors.subText, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _TaskCard(
                task: tasks[i],
                statusColor: _statusColor(tasks[i].status),
                statusLabel: _statusLabel(tasks[i].status),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.focusedMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.text),
            onPressed: onPrev,
          ),
          Text(
            DateFormat('MMMM yyyy').format(focusedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.text),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        children: List.generate(7, (i) {
          final isSunSat = i == 0 || i == 6;
          return Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSunSat ? Colors.red.shade300 : AppColors.subText,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<String, List<Task>> tasksByDay;
  final ValueChanged<DateTime> onDayTap;
  final Color Function(String?) statusColor;
  final String Function(DateTime) dateKey;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.tasksByDay,
    required this.onDayTap,
    required this.statusColor,
    required this.dateKey,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    // weekday: Mon=1…Sun=7 → offset so Sunday=0
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();
    final todayKey = dateKey(today);
    final selectedKey = selectedDay != null ? dateKey(selectedDay!) : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - startOffset + 1;

              if (day < 1 || day > lastDay.day) {
                return const Expanded(child: SizedBox(height: 52));
              }

              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final key = dateKey(date);
              final dayTasks = tasksByDay[key] ?? [];
              final isSelected = key == selectedKey;
              final isToday = key == todayKey;
              final isSunSat = col == 0 || col == 6;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan
                          : isToday
                          ? AppColors.cyan.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : isSunSat
                                ? Colors.red.shade400
                                : AppColors.text,
                          ),
                        ),
                        if (dayTasks.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayTasks
                                .take(3)
                                .map(
                                  (t) => Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : statusColor(t.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final Color statusColor;
  final String statusLabel;

  const _TaskCard({
    required this.task,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status bar
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.subText, size: 18),
          ],
        ),
      ),
    );
  }
}
