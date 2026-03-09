import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';

class StatusTabs extends ConsumerStatefulWidget {
  final Function(int index)? onTabChange;

  const StatusTabs({super.key, this.onTabChange});

  @override
  ConsumerState<StatusTabs> createState() => _StatusTabsState();
}

class _StatusTabsState extends ConsumerState<StatusTabs> {
  int _selectedIndex = 0;

  static const List<Map<String, dynamic>> _tabDefs = [
    {'status': 'todo', 'icon': Icons.radio_button_unchecked},
    {'status': 'doing', 'icon': Icons.play_circle_outline},
    {'status': 'done', 'icon': Icons.check_circle_outline},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final tasksAsync = user != null
        ? ref.watch(userTasksProvider(user.id))
        : const AsyncValue<List<Task>>.data([]);

    final tasks = (tasksAsync.asData?.value ?? []);

    int countFor(String status) =>
        tasks.where((t) => (t.status ?? 'todo') == status).length;

    final labels = [
      'Todo (${countFor('todo')})',
      'Doing (${countFor('doing')})',
      'Done (${countFor('done')})',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabDefs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final bool isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              widget.onTabChange?.call(index);
            },
            child: StatusPill(
              icon: _tabDefs[index]['icon'] as IconData,
              label: labels[index],
              isActive: isSelected,
            ),
          );
        },
      ),
    );
  }
}

// --- StatusPill (เน€เธซเธกเธทเธญเธเน€เธ”เธดเธก เธเธฃเธฑเธเนเธเน const เธเธดเธ”เธซเธเนเธญเธข) ---
class StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    // เนเธเน AnimatedContainer เน€เธเธทเนเธญเธเธงเธฒเธกเธชเธกเธนเธ—เน€เธงเธฅเธฒเน€เธเธฅเธตเนเธขเธเธชเธต (Optional)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.cyan : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                const BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : AppColors.subText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : AppColors.text.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
