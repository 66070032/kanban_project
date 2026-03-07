import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widget/group_card.dart';
import '../../../misc/header.dart';
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
              const Header(),
              const GroupTab(),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  children: const [
                    GroupCard(
                      groupName: 'Development Team',
                      taskCount: 5,
                      totalMembers: 8,
                      hasNotification: true,
                      iconData: Icons.science_outlined,
                      iconColor: Color.fromARGB(255, 147, 37, 255),
                      iconBgColor: Color.fromARGB(255, 227, 183, 255),
                      memberAvatars: [
                        'https://i.pravatar.cc/150?img=11',
                        'https://i.pravatar.cc/150?img=12',
                        'https://i.pravatar.cc/150?img=13',
                      ],
                    ),
                    GroupCard(
                      groupName: 'Design Team',
                      taskCount: 3,
                      totalMembers: 5,
                      iconData: Icons.design_services_outlined,
                      iconColor: Color.fromARGB(255, 255, 147, 37),
                      iconBgColor: Color.fromARGB(255, 255, 227, 183),
                      memberAvatars: [
                        'https://i.pravatar.cc/150?img=41',
                        'https://i.pravatar.cc/150?img=42',
                        'https://i.pravatar.cc/150?img=43',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
