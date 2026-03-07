import 'package:flutter/material.dart';

class UpcomingTasksList extends StatelessWidget {
  const UpcomingTasksList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "TODAY",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Task Cards
          const TaskCard(),
          const SizedBox(height: 16),
          const TaskCard(),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High Priority Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5E5), // Light Red Bg
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "HIGH PRIORITY",
                      style: TextStyle(
                        color: Color(0xFFFF3B30), // Dark Red Text
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  const Text(
                    "Task Title",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Avatar Placeholder
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bottom Row (Date & Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.alarm, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    "Due December 25, 2025",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // See More Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C7FF), // Cyan
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "See More",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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