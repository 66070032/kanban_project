import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/group_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/group_chat_service.dart';
import '../task/pages/task_detail.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;

  const ChatRoomPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Load messages and set group ID on the notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider.notifier).loadMessages(widget.groupId);
    });
    // Poll for new messages every 5 seconds (silent refresh)
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref
            .read(chatNotifierProvider.notifier)
            .loadMessages(widget.groupId, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final chatAsync = ref.watch(chatNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            ref.invalidate(groupsNotifierProvider);
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final membersAsync = ref.watch(
                  groupMembersProvider(widget.groupId),
                );
                return membersAsync.when(
                  data: (members) => Text(
                    '${members.length} member${members.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded, color: Colors.cyan),
            tooltip: 'Group Tasks',
            onPressed: () => _showGroupTasks(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.cyan),
            onPressed: () => _showAddMemberDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () => _showGroupInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load messages',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(chatNotifierProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                _scrollToBottom();

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello or create a task!',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = user != null && '${msg.senderId}' == user.id;
                    final showAvatar =
                        index == 0 ||
                        messages[index - 1].senderId != msg.senderId;

                    return _ChatBubble(
                      message: msg,
                      isMe: isMe,
                      showAvatar: showAvatar,
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          _ChatInputBar(
            controller: _msgController,
            onSend: () async {
              final text = _msgController.text.trim();
              if (text.isEmpty) return;
              _msgController.clear();
              await ref.read(chatNotifierProvider.notifier).sendMessage(text);
            },
            onCreateTask: () => _showCreateTaskSheet(context),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Add Member'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: searching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      onPressed: () async {
                        final q = searchController.text.trim();
                        if (q.length < 2) return;
                        setDialogState(() => searching = true);
                        try {
                          final res = await _searchUsers(q);
                          setDialogState(() {
                            results = res;
                            searching = false;
                          });
                        } catch (_) {
                          setDialogState(() => searching = false);
                        }
                      },
                    ),
                  ),
                  onSubmitted: (q) async {
                    if (q.trim().length < 2) return;
                    setDialogState(() => searching = true);
                    try {
                      final res = await _searchUsers(q.trim());
                      setDialogState(() {
                        results = res;
                        searching = false;
                      });
                    } catch (_) {
                      setDialogState(() => searching = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (results.isEmpty && !searching)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Search for users to add',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ...results.map(
                  (u) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.cyan[100],
                      child: Text(
                        (u['display_name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.cyan),
                      ),
                    ),
                    title: Text(u['display_name'] ?? ''),
                    subtitle: Text(
                      u['email'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.cyan),
                      onPressed: () async {
                        final success = await ref
                            .read(groupsNotifierProvider.notifier)
                            .addMember(widget.groupId, '${u['id']}');
                        if (success && ctx.mounted) {
                          ref.invalidate(groupMembersProvider(widget.groupId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${u['display_name']} added!'),
                            ),
                          );
                          // Remove from results
                          setDialogState(() {
                            results.removeWhere((r) => r['id'] == u['id']);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    try {
      return await GroupChatService.searchUsers(widget.groupId, query);
    } catch (_) {
      return [];
    }
  }

  void _showGroupInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.groupName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Members',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer(
                builder: (ctx, ref, _) {
                  final membersAsync = ref.watch(
                    groupMembersProvider(widget.groupId),
                  );
                  return membersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load members')),
                    data: (members) => ListView.builder(
                      controller: scrollCtrl,
                      itemCount: members.length,
                      itemBuilder: (ctx, i) {
                        final m = members[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan[100],
                            child: Text(
                              m.displayName.isNotEmpty
                                  ? m.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.cyan),
                            ),
                          ),
                          title: Text(m.displayName),
                          subtitle: Text(
                            m.email,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: m.role == 'admin'
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedAssigneeId;
    String? selectedAssigneeName;
    DateTime? selectedDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'This task will be shared in the chat',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Task title *',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              // Assignee picker
              Consumer(
                builder: (ctx, ref, _) {
                  final membersAsync = ref.watch(
                    groupMembersProvider(widget.groupId),
                  );
                  return membersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (members) => InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: ctx,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (pickCtx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Assign to',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ...members.map(
                                  (m) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.cyan[100],
                                      child: Text(
                                        m.displayName.isNotEmpty
                                            ? m.displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                        ),
                                      ),
                                    ),
                                    title: Text(m.displayName),
                                    trailing: selectedAssigneeId == m.id
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.cyan,
                                          )
                                        : null,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedAssigneeId = m.id;
                                        selectedAssigneeName = m.displayName;
                                      });
                                      Navigator.pop(pickCtx);
                                    },
                                  ),
                                ),
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  title: const Text('Unassigned'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedAssigneeId = null;
                                      selectedAssigneeName = null;
                                    });
                                    Navigator.pop(pickCtx);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedAssigneeName ?? 'Assign to...',
                              style: TextStyle(
                                color: selectedAssigneeName != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Due date picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setSheetState(() => selectedDueDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedDueDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(selectedDueDate!)
                            : 'Due date (optional)',
                        style: TextStyle(
                          color: selectedDueDate != null
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      if (selectedDueDate != null)
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedDueDate = null),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    Navigator.pop(ctx);

                    await ref
                        .read(chatNotifierProvider.notifier)
                        .sendTaskMessage(
                          title: title,
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          assigneeId: selectedAssigneeId,
                          dueAt: selectedDueDate?.toIso8601String(),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create & Share Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupTasks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Group Tasks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Consumer(
                    builder: (ctx, ref, _) {
                      final tasksAsync = ref.watch(
                        groupTasksProvider(widget.groupId),
                      );
                      return tasksAsync.when(
                        data: (tasks) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyan[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.cyan,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer(
                builder: (ctx, ref, _) {
                  final tasksAsync = ref.watch(
                    groupTasksProvider(widget.groupId),
                  );
                  return tasksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load tasks')),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.task_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No tasks yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a task in the chat to get started',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          return _GroupTaskTile(
                            task: task,
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailPage(task: task),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Bubble ───

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isTask = message.messageType == 'task';

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 12 : 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showAvatar && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _avatarColor(message.senderId),
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (!isMe)
                const SizedBox(width: 28),
              const SizedBox(width: 6),
              Flexible(
                child: isTask
                    ? _TaskBubble(message: message, isMe: isMe)
                    : _TextBubble(message: message, isMe: isMe),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String id) {
    final colors = [
      Colors.cyan,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}

class _TextBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _TextBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.cyan : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey[400],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TaskBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;

  const _TaskBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse task info from the message content
    final lines = message.content.split('\n');
    final titleLine = lines.isNotEmpty
        ? lines[0].replaceFirst(RegExp(r'^📋\s*New Task:\s*'), '')
        : 'Task';
    final assigneeLine = lines.length > 1 && lines[1].startsWith('Assigned to:')
        ? lines[1].replaceFirst('Assigned to: ', '')
        : null;
    final dueLine = lines.length > 2 && lines.last.startsWith('Due:')
        ? lines.last.replaceFirst('Due: ', '')
        : null;

    return GestureDetector(
      onTap: () {
        if (message.taskId != null) {
          _openTaskDetail(context, ref, message.taskId!);
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.cyan.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Task Created',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'To Do',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleLine,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (assigneeLine != null)
                    _infoRow(Icons.person_outline, 'Assigned to', assigneeLine),
                  if (dueLine != null)
                    _infoRow(Icons.calendar_today_outlined, 'Due', dueLine),
                  const SizedBox(height: 8),
                  // Tap hint
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'Tap to view details →',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.cyan[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer with timestamp
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskDetail(BuildContext context, WidgetRef ref, int taskId) async {
    try {
      final task = await TaskService.getTaskById(taskId);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load task details')),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Group Task Tile ───

class _GroupTaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _GroupTaskTile({required this.task, required this.onTap});

  static const _statusMeta = {
    'todo': {
      'label': 'To Do',
      'color': Color(0xFFE53935),
      'bg': Color(0xFFFFEEEE),
    },
    'doing': {
      'label': 'In Progress',
      'color': Color(0xFF1E88E5),
      'bg': Color(0xFFE3F2FD),
    },
    'done': {
      'label': 'Done',
      'color': Color(0xFF43A047),
      'bg': Color(0xFFE8F5E9),
    },
  };

  @override
  Widget build(BuildContext context) {
    final status = task.status ?? 'todo';
    final meta = _statusMeta[status] ?? _statusMeta['todo']!;
    final bool isOverdue =
        task.dueAt != null &&
        task.dueAt!.isBefore(DateTime.now()) &&
        status != 'done';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (meta['color'] as Color).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: meta['bg'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                status == 'done'
                    ? Icons.check_circle_outline
                    : status == 'doing'
                    ? Icons.pending_outlined
                    : Icons.radio_button_unchecked,
                color: meta['color'] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      decoration: status == 'done'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: meta['bg'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meta['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: meta['color'] as Color,
                          ),
                        ),
                      ),
                      if (task.assigneeName != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            task.assigneeName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (task.dueAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: isOverdue ? Colors.red : Colors.grey[400],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          DateFormat('MMM dd').format(task.dueAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? Colors.red : Colors.grey[500],
                            fontWeight: isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Input Bar ───

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCreateTask;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Task create button
          IconButton(
            onPressed: onCreateTask,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyan[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_task, color: Colors.cyan, size: 22),
            ),
            tooltip: 'Create Task',
          ),
          // Text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
