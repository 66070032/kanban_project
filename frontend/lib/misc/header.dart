import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class Header extends ConsumerWidget {
  const Header({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, MMMM dd').format(DateTime.now());
  }

  ImageProvider? _buildAvatarImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma == -1) return null;
      return MemoryImage(base64Decode(url.substring(comma + 1)));
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Guest';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildAvatarImage(user?.avatarUrl) != null
                  ? Image(
                      key: ValueKey(user?.avatarUrl),
                      image: _buildAvatarImage(user!.avatarUrl!)!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    )
                  : Container(
                      color: AppColors.lightGray,
                      alignment: Alignment.center,
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_getGreeting()}, $userName',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 28),
                color: AppColors.text,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightGray, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
