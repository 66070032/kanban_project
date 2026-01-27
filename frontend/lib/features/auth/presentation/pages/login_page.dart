import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/auth_input_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                  const AuthInputField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  const AuthInputField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),

                  // Button
                  PrimaryButton(
                    text: 'Login',
                    onPressed: () {
                      debugPrint("Login Pressed");
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
}
