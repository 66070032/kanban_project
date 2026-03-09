import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/index.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';

void _showChangeNameDialog(BuildContext context, WidgetRef ref, User user) {
  final controller = TextEditingController(text: user.displayName);
  showDialog(
    context: context,
    builder: (ctx) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Change Account Name',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Display name',
              labelStyle: const TextStyle(color: AppColors.subText),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cyan, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.subText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      setState(() => isLoading = true);
                      try {
                        final updated = await UserService.updateUser(
                          user.id.toString(),
                          displayName: name,
                          avatarUrl: user.avatarUrl,
                        );
                        ref.read(authProvider.notifier).setUser(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Name updated successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
}

void _showChangePasswordDialog(BuildContext context, WidgetRef ref, User user) {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) {
      bool isLoading = false;
      bool showCurrent = false;
      bool showNew = false;
      bool showConfirm = false;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Change Password',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: !showCurrent,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  labelStyle: const TextStyle(color: AppColors.subText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.cyan,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrent ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.subText,
                    ),
                    onPressed: () => setState(() => showCurrent = !showCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: !showNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  labelStyle: const TextStyle(color: AppColors.subText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.cyan,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNew ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.subText,
                    ),
                    onPressed: () => setState(() => showNew = !showNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: !showConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  labelStyle: const TextStyle(color: AppColors.subText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.cyan,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.subText,
                    ),
                    onPressed: () => setState(() => showConfirm = !showConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.subText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final current = currentCtrl.text;
                      final newPass = newCtrl.text;
                      final confirm = confirmCtrl.text;
                      if (current.isEmpty ||
                          newPass.isEmpty ||
                          confirm.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }
                      if (newPass != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New passwords do not match'),
                          ),
                        );
                        return;
                      }
                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => isLoading = true);
                      try {
                        await UserService.changePassword(
                          user.id.toString(),
                          currentPassword: current,
                          newPassword: newPass,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      );
    },
  );
}

void _showChangeAvatarDialog(BuildContext context, WidgetRef ref, User user) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AvatarPickerSheet(user: user),
  );
}

class _AvatarPickerSheet extends ConsumerStatefulWidget {
  final User user;
  const _AvatarPickerSheet({required this.user});

  @override
  ConsumerState<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<_AvatarPickerSheet> {
  File? _pickedFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

  ImageProvider? _buildAvatarImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma == -1) return null;
      return MemoryImage(base64Decode(url.substring(comma + 1)));
    }
    return NetworkImage(url);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 256,
        maxHeight: 256,
      );
      if (picked != null) {
        setState(() => _pickedFile = File(picked.path));
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'channel-error'
                  ? 'Could not open picker. Please grant camera/storage permission and try again.'
                  : 'Error: ${e.message}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = await UserService.uploadAvatar(
        widget.user.id.toString(),
        _pickedFile!.path,
        displayName: widget.user.displayName,
      );
      // Clear Flutter's image cache so the new avatar is fetched fresh
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      // Update auth state using this widget's own ref (ConsumerState)
      ref.read(authProvider.notifier).setUser(updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.subText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Change Profile Picture',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          // Preview
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.lightGray,
                  backgroundImage: _pickedFile != null
                      ? FileImage(_pickedFile!) as ImageProvider
                      : _buildAvatarImageProvider(widget.user.avatarUrl),
                  child: (_pickedFile == null && widget.user.avatarUrl == null)
                      ? const Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.subText,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _upload,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Upload Photo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.subText.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.cyan, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTab extends ConsumerWidget {
  final dynamic user;

  const ProfileTab({required this.user, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authProvider directly so the header re-renders on any profile update
    final liveUser = ref.watch(authProvider) ?? user;
    final tasksCount = ref.watch(taskCountProvider);
    final remindersCount = ref.watch(reminderCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          ProfileHeader(user: liveUser),
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
                onTap: () {
                  final u = ref.read(authProvider);
                  if (u != null) _showChangeNameDialog(context, ref, u);
                },
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () {
                  final u = ref.read(authProvider);
                  if (u != null) _showChangePasswordDialog(context, ref, u);
                },
              ),
              CustomDivider(),
              MenuItem(
                icon: Icons.camera_alt_outlined,
                title: 'Change profile picture',
                onTap: () {
                  final u = ref.read(authProvider);
                  if (u != null) _showChangeAvatarDialog(context, ref, u);
                },
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
