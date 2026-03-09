import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';

void showChangePasswordDialog(BuildContext context, WidgetRef ref, User user) {
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
              _PasswordField(
                controller: currentCtrl,
                label: 'Current password',
                obscure: !showCurrent,
                onToggle: () => setState(() => showCurrent = !showCurrent),
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: newCtrl,
                label: 'New password',
                obscure: !showNew,
                onToggle: () => setState(() => showNew = !showNew),
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: confirmCtrl,
                label: 'Confirm new password',
                obscure: !showConfirm,
                onToggle: () => setState(() => showConfirm = !showConfirm),
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.subText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: AppColors.subText,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
