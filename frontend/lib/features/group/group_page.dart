import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import 'group_cards.dart';
import '/misc/header.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  int _tagIndex = 0;
  final List<String> _tags = ['All', 'Recent', 'Favorites', 'Archived'];

  // Dummy Data
  final List<GroupModel> _groups = List.generate(
    5,
    (index) => GroupModel(
      title: "Group Title",
      subtitle: "3 Works Remaining",
      memberCount: 2,
      hasUpdate: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tags.length, (index) {
                    final bool isSelected = _tagIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(_tags[index]),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: Colors.cyan,
                        backgroundColor: Colors.transparent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: isSelected
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade300),
                        onSelected: (val) {
                          setState(() => _tagIndex = index);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _groups.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const AddGroupCard();
                    }
                    return GroupCard(group: _groups[index - 1]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
