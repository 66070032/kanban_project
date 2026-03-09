import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/index.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';

class ProfileTab extends ConsumerWidget {
  final dynamic user;

  const ProfileTab({required this.user, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksCount = ref.watch(taskCountProvider);
    final remindersCount = ref.watch(reminderCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          ProfileHeader(user: user),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: tasksCount.when(
                  data: (count) => StatCard(
                    label: 'Tasks Left',
                    value: count.toString(),
                    icon: Icons.assignment_outlined,
                    iconColor: AppColors.cyan,
                  ),
                  loading: () => const StatCard(
                    label: 'Tasks Left',
                    value: '...',
                    icon: Icons.assignment_outlined,
                    iconColor: AppColors.cyan,
                  ),
                  error: (_, __) => const StatCard(
                    label: 'Tasks Left',
                    value: '0',
                    icon: Icons.assignment_outlined,
                    iconColor: AppColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: remindersCount.when(
                  data: (count) => StatCard(
                    label: 'Reminders',
                    value: count.toString(),
                    icon: Icons.notifications_outlined,
                    iconColor: Color(0xFFFF9052),
                  ),
                  loading: () => const StatCard(
                    label: 'Reminders',
                    value: '...',
                    icon: Icons.notifications_outlined,
                    iconColor: Color(0xFFFF9052),
                  ),
                  error: (_, __) => const StatCard(
                    label: 'Reminders',
                    value: '0',
                    icon: Icons.notifications_outlined,
                    iconColor: Color(0xFFFF9052),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SectionLabel(title: 'Account'),
          const SizedBox(height: 8),
          MenuContainer(
            children: [
              MenuItem(
                icon: Icons.person_outline,
                title: 'Change account name',
                onTap: () {},
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () {},
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.camera_alt_outlined,
                title: 'Change profile picture',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionLabel(title: 'General'),
          const SizedBox(height: 8),
          MenuContainer(
            children: [
              MenuItem(
                icon: Icons.info_outline,
                title: 'About us',
                onTap: () {},
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Feedback',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
