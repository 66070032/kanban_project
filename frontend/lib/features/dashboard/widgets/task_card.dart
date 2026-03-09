import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';

/// Reusable task card used in upcoming tasks list, calendar, and other views.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onTap});

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
            _buildTopRow(statusColor, statusBg, statusLabel, isOverdue),
            const SizedBox(height: 12),
            _buildTitle(status),
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
            _buildBottomRow(statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(
    Color statusColor,
    Color statusBg,
    String statusLabel,
    bool isOverdue,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        _buildDueDateBadge(isOverdue),
      ],
    );
  }

  Widget _buildDueDateBadge(bool isOverdue) {
    if (task.dueAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isOverdue ? const Color(0xFFFFEEEE) : const Color(0xFFF0F4FF),
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
              formatDate(task.dueAt),
              style: TextStyle(
                color: isOverdue ? Colors.red : AppColors.subText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }

  Widget _buildTitle(String status) {
    return Text(
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
    );
  }

  Widget _buildBottomRow(Color statusColor) {
    final isGroup = task.isFromGroup;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isGroup
                ? Colors.cyan.withValues(alpha: 0.15)
                : statusColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isGroup ? Icons.chat_bubble_outline : Icons.person_outline,
            size: 14,
            color: isGroup ? Colors.cyan : statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.originLabel,
            style: TextStyle(
              color: isGroup ? Colors.cyan : AppColors.subText,
              fontSize: 12,
              fontWeight: isGroup ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
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
    );
  }

  static String formatDate(DateTime? date) {
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
