import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatusTabs extends StatelessWidget {
  const StatusTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          StatusPill(
            icon: Icons.radio_button_unchecked,
            label: "Todo (12)",
            isActive: true,
          ),
          SizedBox(width: 12),
          StatusPill(
            icon: Icons.play_circle_outline,
            label: "Doing (3)",
            isActive: false,
          ),
          SizedBox(width: 12),
          StatusPill(
            icon: Icons.check_circle_outline,
            label: "Done (5)",
            isActive: false,
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.cyan : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.3),
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
              color: isActive ? Colors.white : AppColors.text.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
