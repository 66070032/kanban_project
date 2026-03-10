import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../main_wrapper.dart';
import '../../../core/config/app_config.dart';
import '../../../services/background_sync_service.dart';
import '../presentation/widgets/auth_input_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_displayNameController.text.trim().isEmpty) {
      return 'Display name is required';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailController.text.contains('@')) {
      return 'Enter a valid email address';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'display_name': _displayNameController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['user'] != null) {
        final user = User.fromJson(data['user']);
        ref.read(authProvider.notifier).setUser(user);

        // Persist for background sync & start periodic polling
        await BackgroundSyncService.saveUserSession(user.id, user.displayName);
        await BackgroundSyncService.registerPeriodicSync();
        await BackgroundSyncService.startForegroundService();
        BackgroundSyncService.runSync();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapper()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage =
              data['message'] ?? 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Server error. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F7FF), Color(0xFFB3EDFF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 60,
                    width: 60,
                    child: Icon(
                      Icons.person_add,
                      size: 60,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: AppColors.subText,
                    ),
                  ),
                  const SizedBox(height: 32),

                  AuthInputField(
                    label: 'Display Name',
                    hintText: 'Enter your name',
                    controller: _displayNameController,
                  ),
                  const SizedBox(height: 20),
                  AuthInputField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),
                  AuthInputField(
                    label: 'Password',
                    hintText: 'At least 6 characters',
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 20),
                  AuthInputField(
                    label: 'Confirm Password',
                    hintText: 'Repeat your password',
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator(color: AppColors.cyan)
                      : PrimaryButton(
                          text: 'Register',
                          onPressed: _handleRegister,
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: AppColors.subText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Log in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
