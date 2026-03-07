import 'package:flutter/material.dart';

class OverlappingAvatars extends StatelessWidget {
  final List<String> imageUrls;
  final int totalMembers;

  const OverlappingAvatars({
    super.key,
    required this.imageUrls,
    required this.totalMembers,
  });

  @override
  Widget build(BuildContext context) {
    // Show a maximum of 3 avatars to match the design
    final displayCount = imageUrls.length > 3 ? 3 : imageUrls.length;
    final remainingCount = totalMembers - displayCount;

    return Row(
      children: [
        if (displayCount > 0)
          SizedBox(
            width: 32.0 + ((displayCount - 1) * 20.0),
            height: 32,
            child: Stack(
              children: List.generate(
                displayCount,
                (index) => Positioned(
                  left: index * 20.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 217, 217, 217),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      // Use NetworkImage for web URLs, or change to AssetImage for local files
                      image: DecorationImage(
                        image: NetworkImage(imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (remainingCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '+$remainingCount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(179, 103, 96, 96),
            ),
          ),
        ],
      ],
    );
  }
}