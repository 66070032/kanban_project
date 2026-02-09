import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class UpcomingTasksList extends StatelessWidget {
  const UpcomingTasksList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Upcoming Tasks",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Task 1
          const TaskCard(
            tagLabel: "High Priority",
            tagColor: AppColors.redTagBg,
            tagTextColor: AppColors.redTagText,

            timeLabel: "Due Tomorrow • 4:00 PM",
            title: "History Project Research",
            subtitle: "Find primary sources for the industrial revolution.",
            // senderName: "Sarah",
            groupImage:
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCQUq7KoMp-wQHitECJg8-i3mKRV5_kbGJvNHJ0iNzKECK-rjkr-KqX4N9zmN9n4ZRNIyYyR7wIXf2JHxDWQEjKsWo38NZX-l1qnmr99T_Z9CEmVNGlFTs5AC_u3_B4jOXbbF8MmWl8wk2rxW68qlpKd1JrRh2AG0Mybnz6okqQEYiIZJzGDNrQ6WUR6sjuOtHSuJvbDDjeFlEOQOQ27pmzkNI6po8xKzz4x24I27fTTrWrmDCK9sXx-iwyT4hiH33VFnWr2tZ-xLo",
            duration: "0:32",
            showWaveform: true,
          ),
          const SizedBox(height: 16),
          // Task 2
          const TaskCard(
            tagLabel: "High Priority",
            tagColor: AppColors.redTagBg,
            tagTextColor: AppColors.redTagText,
            timeLabel: "Today • 2:30 PM",
            title: "Team Meeting Notes",
            subtitle: "Review the audio recording from yesterday's sync.",
            // senderName: "Mark",
            groupImage:
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBnKFraXbKRAaEbOP4LatjKcFAecciXaHrG3odWmMYXA3YwWocA_CnsKf7gyUU3tvWqFXKmGR2L3Pc2jzks_E50T0HlSCvUgZP0DITaJcBVs6bYKF0HTMpp3N9rhXKSEFeeJ1G-Rd6aHr4ieKwTHlVP3QnLZj-B4YcPiqSTiwtLQn0BJHlQG1cIJR5PiT-Gm8b0_qU4UA5n9SFyQs__mfJPNMP7XJhwn11iLz4vPAsdTj-iIVvHREWHnF4AmCZWTntIBwgKqYQlRcI",
            duration: "1:15",
            showWaveform: false,
          ),
          const SizedBox(height: 16),
          // Task 3
          const TaskCard(
            tagLabel: "High Priority",
            tagColor: AppColors.redTagBg,
            tagTextColor: AppColors.redTagText,
            timeLabel: "Friday • 9:00 AM",
            title: "Review Biology Slides",
            subtitle: "Chapter 4: Cell structure and functions prep.",
            // senderName: "Prof. Davis",
            groupImage:
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCOHyQUwQ30lDhF3wJd5Cv-82KJK2MCat_51Gf1KDUkQAbI8hKpswoFCfKf5h4k6BazlfxdkEHl0q3MvtM4-RNwBUQQvtWg1O_T627dD6C8BSI0CPZ7JhZsmemGWB1RXtTQjnlOk4pQBAgM0qcC_Gcu8SGxhuEAO6IuJg_tTyaf2ueiXkmP0U7WxCRZZK3LFuRzrWt2hMxYxlUPCQzvYYVJQg0odSaYoqpKJTE3-0E01PHIY_6vZlznyk56ns81uWSNuYJUJEX0K2w",
            duration: "0:45",
            showWaveform: false,
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String tagLabel;
  final Color tagColor;
  final Color tagTextColor;
  final String timeLabel;
  final String title;
  final String subtitle;
  // final String senderName;
  final String groupImage;
  final String duration;
  final bool showWaveform;

  const TaskCard({
    super.key,
    required this.tagLabel,
    required this.tagColor,
    required this.tagTextColor,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    // required this.senderName,
    required this.groupImage,
    required this.duration,
    required this.showWaveform,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Content & Play Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag & Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tagTextColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tagLabel,
                                style: TextStyle(
                                  color: tagTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   subtitle,
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: const TextStyle(
                    //     color: AppColors.subText,
                    //     fontSize: 13,
                    //   ),
                    // ),
                    Text(
                      timeLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Group Image
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(groupImage),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          // Footer: Audio Visualizer / Time
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showWaveform)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildWaveBar(8),
                    _buildWaveBar(12),
                    _buildWaveBar(16),
                    _buildWaveBar(8),
                    _buildWaveBar(12),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq,
                      color: AppColors.subText,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: const BoxDecoration(
        color: AppColors.cyan,
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}
