import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/index.dart';
import '../../auth/pages/login_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/background_sync_service.dart';
import 'profile_tab.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    return Container(
      color: const Color(0xFFF2F5F9),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: ProfileTab(user: user)),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SecondaryButton(
                label: 'Log Out',
                onPressed: () async {
                  ref.read(authProvider.notifier).logout();
                  await BackgroundSyncService.clearUserSession();
                  await BackgroundSyncService.cancelAll();

                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
