import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';

class UpcomingTasksList extends ConsumerWidget {
  const UpcomingTasksList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue.loading();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Upcoming Tasks",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (user == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Please log in to view tasks.",
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
              error: (error, stackTrace) => _buildEmptyState(),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyState();
                }

                final displayTasks = tasks.take(3).toList();

                return Column(
                  children: displayTasks.map<Widget>((task) {
                    final title = task.title;
                    final description = task.description ?? "";
                    final status = task.status ?? "todo";
                    final dueAt = task.dueAt;
                    // Temporarily set to false
                    final hasVoice = false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TaskCard(
                        tagLabel: _formatStatus(status),
                        tagColor: _getTagColor(status),
                        tagTextColor: _getTagTextColor(status),
                        timeLabel: _formatDate(dueAt),
                        title: title,
                        subtitle: description,
                        groupImage:
                            "https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}&background=random&format=png",
                        duration: hasVoice ? "0:30" : "N/A",
                        showWaveform: hasVoice,
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

  // --- Helper Methods ---

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 56, color: AppColors.cyan),
            SizedBox(height: 16),
            Text(
              "Yay! You got no tasks anymore, cheers! 🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return "TODO";
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _getTagColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green.withOpacity(0.15);
      case 'doing':
      case 'in_progress':
        return Colors.orange.withOpacity(0.15);
      default:
        return AppColors.redTagBg;
    }
  }

  Color _getTagTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'doing':
      case 'in_progress':
        return Colors.orange;
      default:
        return AppColors.redTagText;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "No Due Date";

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1;

    int hour = date.hour;
    String period = "AM";
    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;

    final timeStr = "$hour:${date.minute.toString().padLeft(2, '0')} $period";

    if (isToday) return "Today • $timeStr";
    if (isTomorrow) return "Tomorrow • $timeStr";

    return "${date.day}/${date.month}/${date.year} • $timeStr";
  }
}

class TaskCard extends StatelessWidget {
  final String tagLabel;
  final Color tagColor;
  final Color tagTextColor;
  final String timeLabel;
  final String title;
  final String subtitle;
  final String? groupImage;
  final String duration;
  final bool showWaveform;

  const TaskCard({
    super.key,
    required this.tagLabel,
    required this.tagColor,
    required this.tagTextColor,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    this.groupImage,
    required this.duration,
    required this.showWaveform,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tagTextColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tagLabel,
                                style: TextStyle(
                                  color: tagTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Displaying your dynamic subtitle!
                    if (subtitle.isNotEmpty) ...[
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      timeLabel,

                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: groupImage != null && groupImage!.isNotEmpty
                    ? NetworkImage(groupImage!)
                    : null,
                child: groupImage == null || groupImage!.isEmpty
                    ? Text(
                        title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showWaveform)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildWaveBar(8),
                    _buildWaveBar(12),
                    _buildWaveBar(16),
                    _buildWaveBar(8),
                    _buildWaveBar(12),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq,
                      color: AppColors.subText,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: const BoxDecoration(
        color: AppColors.cyan,
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}
