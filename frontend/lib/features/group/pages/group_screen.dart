import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widget/group_card.dart';
import '../../dashboard/widgets/dashboard_header.dart';
import '../../dashboard/widgets/navigation.dart';
import '../widget/group_tab.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const DashboardHeader(),
              const GroupTab(),
              const SizedBox(height: 16), // แนะนำให้เพิ่มระยะห่างนิดหน่อย
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: const [
                    GroupCard(
                      groupName: 'Development Team',
                      taskCount: 5,
                      memberCount: 8,
                    ),
                    GroupCard(
                      groupName: 'Design Team',
                      taskCount: 3,
                      memberCount: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }
}
