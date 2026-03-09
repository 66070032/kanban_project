import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GroupTab extends StatefulWidget {
  // เน€เธเธดเนเธก callback เน€เธเธทเนเธญเธชเนเธเธเนเธฒเธเธฅเธฑเธเนเธเธซเธเนเธฒเธซเธฅเธฑเธเธงเนเธฒเน€เธฅเธทเธญเธ tab เนเธซเธ
  final Function(int index)? onTabChange;

  const GroupTab({super.key, this.onTabChange});

  @override
  State<GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends State<GroupTab> {
  // เน€เธเนเธเธเนเธฒ index เธเธญเธ tab เธ—เธตเนเธ–เธนเธเน€เธฅเธทเธญเธ (เน€เธฃเธดเนเธกเธ•เนเธเธ—เธตเน 0)
  int _selectedIndex = 0;

  // เธเนเธญเธกเธนเธฅเธเธญเธ Tab (เธชเธฒเธกเธฒเธฃเธ–เธฃเธฑเธเธกเธฒเธเธฒเธ API เธซเธฃเธทเธญ Prop เนเธ”เนเนเธเธญเธเธฒเธเธ•)
  final List<Map<String, dynamic>> _tabs = [
    {"label": "All"},
    {"label": "Recent"},
    {"label": "Favorites"},
    {"label": "Archived"},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        itemCount: _tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final bool isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              // เน€เธฃเธตเธขเธ callback เธ–เนเธฒเธกเธตเธเธฒเธฃเธชเนเธเธกเธฒ
              if (widget.onTabChange != null) {
                widget.onTabChange!(index);
              }
            },
            child: StatusPill(
              label: tab['label'],
              isActive: isSelected, // เธชเนเธเธเนเธฒ true เธ–เนเธฒ index เธ•เธฃเธเธเธฑเธ
            ),
          );
        },
      ),
    );
  }
}

// --- StatusPill (เน€เธซเธกเธทเธญเธเน€เธ”เธดเธก เธเธฃเธฑเธเนเธเน const เธเธดเธ”เธซเธเนเธญเธข) ---
class StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;

  const StatusPill({super.key, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    // เนเธเน AnimatedContainer เน€เธเธทเนเธญเธเธงเธฒเธกเธชเธกเธนเธ—เน€เธงเธฅเธฒเน€เธเธฅเธตเนเธขเธเธชเธต (Optional)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.cyan : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                const BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: isActive ? Colors.white : AppColors.subText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.text.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
