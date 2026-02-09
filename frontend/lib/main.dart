import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'features/landing/pages/landing_page.dart';
import 'features/profile/pages/profile_pages.dart';
import 'features/dashboard/widgets/dashboard_screen.dart';
import 'features/group/pages/group_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanban App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
      ),
      home: const GroupScreen(),
    );
  }
}
