import 'package:flutter/material.dart' hide DropdownMenuItem;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/index.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/notification_service.dart';
import 'send_notification_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F9),
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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

              // Test Notifications Section
              SectionLabel(title: 'Test Notifications'),
              const SizedBox(height: 8),
              MenuContainer(
                children: [
                  MenuItem(
                    icon: Icons.notifications_active,
                    title: 'Send Instant Notification',
                    onTap: () {
                      NotificationService().showNotification(
                        id: 99999,
                        title: '\u{1F514} Test Notification',
                        body: 'This is a test notification from Kanban App!',
                        payload: 'test',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification sent!')),
                      );
                    },
                  ),
                  CustomDivider(),
                  MenuItem(
                    icon: Icons.schedule,
                    title: 'Schedule in 10 Seconds',
                    onTap: () {
                      NotificationService().scheduleNotification(
                        id: 99998,
                        title: '\u23F0 Scheduled Test',
                        body:
                            'This was scheduled 10 seconds ago. Notifications work!',
                        scheduledTime: DateTime.now().add(
                          const Duration(seconds: 10),
                        ),
                        payload: 'scheduled_test',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notification scheduled in 10 seconds!',
                          ),
                        ),
                      );
                    },
                  ),
                  CustomDivider(),
                  MenuItem(
                    icon: Icons.phone_callback,
                    title: 'Test Fake Incoming Call',
                    onTap: () {
                      NotificationService().showNotification(
                        id: 99997,
                        title: '\u{1F4DE} Incoming Call',
                        body: 'Test Task \u2014 due in 5 minutes!',
                        payload: 'Test Task',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fake call notification sent! Tap it to see incoming call screen.',
                          ),
                        ),
                      );
                    },
                  ),
                  CustomDivider(),
                  MenuItem(
                    icon: Icons.send_rounded,
                    title: 'Send Notification to People',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SendNotificationPage(),
                        ),
                      );
                    },
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
                    value: '1.3.0',
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
        ),
      ),
    );
  }
}
