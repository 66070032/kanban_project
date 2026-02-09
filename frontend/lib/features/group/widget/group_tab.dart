import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GroupTab extends StatefulWidget {
  // เพิ่ม callback เพื่อส่งค่ากลับไปหน้าหลักว่าเลือก tab ไหน
  final Function(int index)? onTabChange;

  const GroupTab({super.key, this.onTabChange});

  @override
  State<GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends State<GroupTab> {
  // เก็บค่า index ของ tab ที่ถูกเลือก (เริ่มต้นที่ 0)
  int _selectedIndex = 0;

  // ข้อมูลของ Tab (สามารถรับมาจาก API หรือ Prop ได้ในอนาคต)
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
              // เรียก callback ถ้ามีการส่งมา
              if (widget.onTabChange != null) {
                widget.onTabChange!(index);
              }
            },
            child: StatusPill(
              label: tab['label'],
              isActive: isSelected, // ส่งค่า true ถ้า index ตรงกัน
            ),
          );
        },
      ),
    );
  }
}

// --- StatusPill (เหมือนเดิม ปรับแค่ const นิดหน่อย) ---
class StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;

  const StatusPill({super.key, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    // ใช้ AnimatedContainer เพื่อความสมูทเวลาเปลี่ยนสี (Optional)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.cyan : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.3),
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
              color: isActive ? Colors.white : AppColors.text.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
