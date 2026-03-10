import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/group_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/reminder_provider.dart';

class SendNotificationPage extends ConsumerStatefulWidget {
  const SendNotificationPage({super.key});

  @override
  ConsumerState<SendNotificationPage> createState() =>
      _SendNotificationPageState();
}

class _SendNotificationPageState extends ConsumerState<SendNotificationPage> {
  final _messageController = TextEditingController();

  GroupModel? _selectedGroup;
  List<GroupMember> _members = [];
  final Set<String> _selectedMemberIds = {};
  bool _loadingMembers = false;
  bool _sending = false;

  DateTime _dueDate = DateTime.now().add(const Duration(minutes: 10));
  TimeOfDay _dueTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers(int groupId) async {
    setState(() => _loadingMembers = true);
    try {
      final members = await ref.read(groupMembersProvider(groupId).future);
      final user = ref.read(authProvider);
      setState(() {
        // Exclude self from the list
        _members = members.where((m) => m.id != user?.id).toList();
        _selectedMemberIds.clear();
        _loadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _members = [];
        _loadingMembers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load members: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  DateTime get _combinedDueDate => DateTime(
    _dueDate.year,
    _dueDate.month,
    _dueDate.day,
    _dueTime.hour,
    _dueTime.minute,
  );

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one person')),
      );
      return;
    }

    setState(() => _sending = true);

    int successCount = 0;
    int failCount = 0;

    for (final memberId in _selectedMemberIds) {
      try {
        await ReminderService.createReminder({
          'userId': memberId,
          'title': message,
          'description':
              'Sent by ${ref.read(authProvider)?.displayName ?? "someone"}',
          'dueDate': _combinedDueDate.toIso8601String(),
        });
        successCount++;
      } catch (_) {
        failCount++;
      }
    }

    if (!mounted) return;
    setState(() => _sending = false);

    final names = _selectedMemberIds
        .map(
          (id) => _members
              .firstWhere((m) => m.id == id, orElse: () => _members.first)
              .displayName,
        )
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount == 0
              ? 'Reminder sent to $successCount people ($names)'
              : 'Sent: $successCount, Failed: $failCount',
        ),
        backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
      ),
    );

    if (failCount == 0) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final groupsAsync = user != null
        ? ref.watch(userGroupsProvider(user.id))
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Send Notification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. Pick Group ───
              _sectionTitle('1. Choose a Group'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: _cardDecoration(),
                child: groupsAsync == null
                    ? const Text('Not logged in')
                    : groupsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                        error: (e, _) => Text('Error: $e'),
                        data: (groups) {
                          if (groups.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No groups yet. Create a group first.',
                                style: TextStyle(color: AppColors.subText),
                              ),
                            );
                          }
                          return DropdownButton<GroupModel>(
                            value: _selectedGroup,
                            hint: const Text('Select group'),
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: groups
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (group) {
                              setState(() => _selectedGroup = group);
                              if (group != null) _loadMembers(group.id);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),

              // ─── 2. Pick Members ───
              _sectionTitle('2. Select People'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(),
                child: _selectedGroup == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Pick a group first',
                          style: TextStyle(color: AppColors.subText),
                        ),
                      )
                    : _loadingMembers
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cyan,
                          ),
                        ),
                      )
                    : _members.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No other members in this group',
                          style: TextStyle(color: AppColors.subText),
                        ),
                      )
                    : Column(
                        children: [
                          // Select All
                          CheckboxListTile(
                            title: Text(
                              'Select All (${_members.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _selectedMemberIds.length == _members.length,
                            activeColor: AppColors.cyan,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedMemberIds.addAll(
                                    _members.map((m) => m.id),
                                  );
                                } else {
                                  _selectedMemberIds.clear();
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          const Divider(height: 1),
                          ..._members.map(
                            (member) => CheckboxListTile(
                              title: Text(member.displayName),
                              subtitle: Text(
                                member.email,
                                style: const TextStyle(fontSize: 12),
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: AppColors.cyan.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  member.displayName.isNotEmpty
                                      ? member.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              value: _selectedMemberIds.contains(member.id),
                              activeColor: AppColors.cyan,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedMemberIds.add(member.id);
                                  } else {
                                    _selectedMemberIds.remove(member.id);
                                  }
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // ─── 3. Message ───
              _sectionTitle('3. Message'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. "Don\'t forget the meeting at 3pm!"',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── 4. Due Date & Time ───
              _sectionTitle('4. When to Notify'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_dueDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.grey[300]),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 20,
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dueTime.format(context),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Recipients will get a notification at this time, plus a fake incoming call 5 minutes before.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),

              // ─── Send Button ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _sending
                        ? 'Sending...'
                        : 'Send to ${_selectedMemberIds.length} ${_selectedMemberIds.length == 1 ? "person" : "people"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    disabledBackgroundColor: AppColors.cyan.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
