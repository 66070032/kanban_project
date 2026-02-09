import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GroupCard extends StatelessWidget {
  final String groupName;
  final int memberCount;
  final int taskCount;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.groupName,
    required this.taskCount,
    required this.memberCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 164,
        height: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$taskCount Works Remaining',
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(179, 103, 96, 96),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$memberCount Members',

              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(179, 103, 96, 96),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
