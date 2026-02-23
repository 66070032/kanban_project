import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanban_project/features/profile/pages/profile_pages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../presentation/widgets/auth_input_field.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../profile/pages/profile_pages.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                  // Logo Placeholder
                  const SizedBox(
                    height: 60,
                    width: 60,
                    child: Icon(Icons.lock, size: 60, color: AppColors.cyan),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Login',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Please sign in to continue.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: AppColors.subText,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Inputs
                  AuthInputField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                  ),
                  const SizedBox(height: 20),
                  AuthInputField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    isPassword: true,
                    controller: passwordController,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Button
                  PrimaryButton(
                    text: 'Login',
                    onPressed: () {
                      handleLogin();
                      /* Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                        (route) =>
                            false, // This returns 'false' to remove all previous routes
                      ); */
                    },
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: AppColors.subText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          debugPrint("Navigate to Sign Up");
                        },
                        child: Text(
                          'Sign up',
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

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://kanban.jokeped.xyz/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint("Login response: $data");
      debugPrint("Status code: ${response.statusCode}");

      if (response.statusCode == 200 && data['user'] != null) {
        final user = User.fromJson(data["user"]);

        ref.read(authProvider.notifier).setUser(user);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
      } else {
        setState(() {
          errorMessage = "Email or password is incorrect";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Server error";
      });
    }

    setState(() {
      isLoading = false;
    });
  }
}
