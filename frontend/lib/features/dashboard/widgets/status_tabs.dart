import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatusTabs extends StatefulWidget {
  // เพิ่ม callback เพื่อส่งค่ากลับไปหน้าหลักว่าเลือก tab ไหน
  final Function(int index)? onTabChange;

  const StatusTabs({super.key, this.onTabChange});

  @override
  State<StatusTabs> createState() => _StatusTabsState();
}

class _StatusTabsState extends State<StatusTabs> {
  // เก็บค่า index ของ tab ที่ถูกเลือก (เริ่มต้นที่ 0)
  int _selectedIndex = 0;

  // ข้อมูลของ Tab (สามารถรับมาจาก API หรือ Prop ได้ในอนาคต)
  final List<Map<String, dynamic>> _tabs = [
    {"label": "Todo (12)", "icon": Icons.radio_button_unchecked},
    {"label": "Doing (3)", "icon": Icons.play_circle_outline},
    {"label": "Done (5)", "icon": Icons.check_circle_outline},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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

class StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;

  const StatusPill({super.key, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00C7FF) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Radio Icon Mimic
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.grey.shade500,
                width: 1.5,
              ),
            ),
            child: isActive
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
