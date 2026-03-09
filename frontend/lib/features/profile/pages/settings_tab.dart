import 'package:flutter/material.dart' hide DropdownMenuItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/index.dart';
import '../../../providers/settings_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Notifications Section
          SectionLabel(title: 'Notifications'),
          const SizedBox(height: 8),
          MenuContainer(
            children: [
              ToggleMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Task Notifications',
                subtitle: 'Get notified about task updates',
                initialValue: ref
                    .watch(notificationSettingsProvider)
                    .taskNotifications,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .updateTaskNotifications(value);
                },
              ),
              CustomDivider(),
              ToggleMenuItem(
                icon: Icons.notifications_active_outlined,
                title: 'Reminder Notifications',
                subtitle: 'Receive reminder alerts',
                initialValue: ref
                    .watch(notificationSettingsProvider)
                    .reminderNotifications,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .updateReminderNotifications(value);
                },
              ),
              CustomDivider(),
              ToggleMenuItem(
                icon: Icons.message_outlined,
                title: 'Message Notifications',
                subtitle: 'Alerts for team messages',
                initialValue: ref
                    .watch(notificationSettingsProvider)
                    .messageNotifications,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .updateMessageNotifications(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Sound & Vibration Section
          SectionLabel(title: 'Sound & Vibration'),
          const SizedBox(height: 8),
          MenuContainer(
            children: [
              ToggleMenuItem(
                icon: Icons.volume_up_outlined,
                title: 'Sound Effects',
                subtitle: 'Play sound for notifications',
                initialValue: ref.watch(soundSettingsProvider).soundEffects,
                onChanged: (value) {
                  ref
                      .read(soundSettingsProvider.notifier)
                      .updateSoundEffects(value);
                },
              ),
              CustomDivider(),
              ToggleMenuItem(
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Haptic feedback on interactions',
                initialValue: ref.watch(soundSettingsProvider).vibration,
                onChanged: (value) {
                  ref
                      .read(soundSettingsProvider.notifier)
                      .updateVibration(value);
                },
              ),
              CustomDivider(),
              DropdownMenuItem(
                icon: Icons.volume_down_outlined,
                title: 'Notification Volume',
                value: ref.watch(soundSettingsProvider).notificationVolume,
                onChanged: (value) {
                  ref
                      .read(soundSettingsProvider.notifier)
                      .updateNotificationVolume(value);
                },
                options: ['Low', 'Normal', 'High'],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // About Section
          SectionLabel(title: 'About'),
          const SizedBox(height: 8),
          MenuContainer(
            children: [
              MenuItemWithValue(
                icon: Icons.info_outline,
                title: 'Version',
                value: '1.0.0',
                onTap: () {},
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                onTap: () {},
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
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
