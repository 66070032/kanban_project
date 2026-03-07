import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../misc/overlapping_avatars.dart'; // Make sure to import the new file!

class GroupCard extends StatelessWidget {
  final String groupName;
  final int taskCount;
  final int totalMembers;
  final List<String> memberAvatars; // List of image URLs
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final bool hasNotification; // Toggles the blue dot
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.groupName,
    required this.taskCount,
    required this.totalMembers,
    required this.memberAvatars,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    this.hasNotification = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 164,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromARGB(255, 230, 230, 230),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow, // Ensure this exists in your app_colors.dart
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  groupName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$taskCount Works Remaining',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(179, 103, 96, 96),
                  ),
                ),
                const Spacer(),
                // Using your new split widget here!
                OverlappingAvatars(
                  imageUrls: memberAvatars,
                  totalMembers: totalMembers,
                ),
              ],
            ),
            if (hasNotification)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 0, 195, 255),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}