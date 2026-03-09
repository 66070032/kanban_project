import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';

class StatusTabs extends ConsumerWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const StatusTabs({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const List<Map<String, dynamic>> _tabs = [
    {
      'status': 'todo',
      'label': 'To Do',
      'icon': Icons.radio_button_unchecked,
      'activeColor': AppColors.redTagText,
      'activeColorCard': AppColors.redTagBg,
    },
    {
      'status': 'doing',
      'label': 'In Progress',
      'icon': Icons.autorenew_rounded,
      'activeColor': AppColors.blueTagText,
      'activeColorCard': AppColors.blueTagBg,
    },
    {
      'status': 'done',
      'label': 'Done',
      'icon': Icons.check_circle_outline_rounded,
      'activeColor': AppColors.greenTagText,
      'activeColorCard': AppColors.greenTagBg,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue<List<Task>>.data([]);
    final tasks = tasksAsync.asData?.value ?? [];

    int countFor(String s) =>
        tasks.where((t) => (t.status ?? 'todo') == s).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                '${tasks.length} total',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final status = tab['status'] as String;
              final isSelected = selectedStatus == status;
              // final count = countFor(status);
              final activeColor = tab['activeColor'] as Color;
              final activeBg = tab['activeColorCard'] as Color;

              return GestureDetector(
                onTap: () => onStatusChanged(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? activeColor : AppColors.subText,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tab['label'] as String,
                        style: TextStyle(
                          color: isSelected ? activeColor : AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.15)
                              : activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${countFor(status)}',
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
