import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../group/pages/group_screen.dart';
import '../../dashboard/widgets/dashboard_screen.dart';
class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, "Home", false, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          }),
          _buildNavItem(Icons.calendar_today_rounded, "Calendar", false),
          _buildNavItem(Icons.folder_open_rounded, "Group", false, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupScreen()),
            );
          }),
          _buildNavItem(Icons.settings_outlined, "Profile", false),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, [
    VoidCallback? onTap,
  ]) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.cyan : const Color(0xFFC4C4C4),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.cyan : const Color(0xFFC4C4C4),
            ),
          ),
        ],
      ),
    );
  }
}
