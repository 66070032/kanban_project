import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.2),
                width: 2,
              ),
              image: const DecorationImage(
                image: NetworkImage(
                  "https://lh3.googleusercontent.com/aida-public/AB6AXuDW3Rqfn_2HqhNxsKkmK7qrOu7s0pWBzktN76f1PpP1r063Q79xXbJ2qLec0PM_YnQDAjFBDeKYZCDn5-uiu16z7Oocoq2mq2okiRvyvD3uYh25j--2ZM8pGipQzdtd0sPJ0oejhBigJHn2NeQkC9-mYmVvZEvmLPFo2Ytx-WBXL6yYePvShfYS1csmHGcy--Ta6GNyyPNg9T21amSLVHWwrabGsbd8wxIwkGSr-UB_B9PyTiHu_dkVQfioAWN0ne-ZRNqC-wotSmo",
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGray, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monday, October 24",
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Good Morning, Alex",
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 28),
                color: AppColors.text,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightGray, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
