import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../models/task_model.dart';
import '../services/group_chat_service.dart';
import 'auth_provider.dart';

// ─── Groups list for current user ───

final userGroupsProvider = FutureProvider.family<List<GroupModel>, String>((
  ref,
  userId,
) async {
  return GroupChatService.getUserGroups(userId);
});

// ─── Group members ───

final groupMembersProvider = FutureProvider.family<List<GroupMember>, int>((
  ref,
  groupId,
) async {
  return GroupChatService.getGroupMembers(groupId);
});

// ─── Chat messages for a group ───

final groupMessagesProvider = FutureProvider.family<List<ChatMessage>, int>((
  ref,
  groupId,
) async {
  return GroupChatService.getMessages(groupId);
});

// ─── Group tasks ───

final groupTasksProvider = FutureProvider.family<List<Task>, int>((
  ref,
  groupId,
) async {
  return GroupChatService.getGroupTasks(groupId);
});

// ─── Groups notifier for mutations ───

class GroupsNotifier extends AsyncNotifier<List<GroupModel>> {
  @override
  Future<List<GroupModel>> build() async {
    final user = ref.watch(authProvider);
    if (user == null) return [];
    return GroupChatService.getUserGroups(user.id);
  }

  Future<GroupModel?> createGroup({
    required String name,
    String? description,
  }) async {
    final user = ref.read(authProvider);
    if (user == null) return null;

    try {
      final group = await GroupChatService.createGroup(
        name: name,
        description: description,
        createdBy: user.id,
      );
      // Refresh the list
      ref.invalidateSelf();
      return group;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteGroup(int groupId) async {
    try {
      await GroupChatService.deleteGroup(groupId);
      state = AsyncData(
        (state.asData?.value ?? []).where((g) => g.id != groupId).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMember(int groupId, String userId) async {
    try {
      await GroupChatService.addMember(groupId, userId);
      ref.invalidate(groupMembersProvider(groupId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMember(int groupId, String userId) async {
    try {
      await GroupChatService.removeMember(groupId, userId);
      ref.invalidate(groupMembersProvider(groupId));
      return true;
    } catch (e) {
      return false;
    }
  }
}

final groupsNotifierProvider =
    AsyncNotifierProvider<GroupsNotifier, List<GroupModel>>(GroupsNotifier.new);

// ─── Chat notifier for sending messages ───

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  int _groupId = 0;

  @override
  Future<List<ChatMessage>> build() async {
    return [];
  }

  Future<void> loadMessages(int groupId, {bool silent = false}) async {
    _groupId = groupId;
    // Only show loading spinner on initial load, not on polls
    if (!silent && state.asData?.value.isEmpty != false) {
      state = const AsyncLoading();
    }
    try {
      final messages = await GroupChatService.getMessages(groupId);
      state = AsyncData(messages);
    } catch (e, st) {
      // On silent refresh, keep old data instead of showing error
      if (!silent) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<bool> sendMessage(String content) async {
    final user = ref.read(authProvider);
    if (user == null) return false;

    try {
      final message = await GroupChatService.sendMessage(
        groupId: _groupId,
        senderId: user.id,
        content: content,
      );
      state = AsyncData([...state.asData?.value ?? [], message]);
      ref.invalidate(groupsNotifierProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendTaskMessage({
    required String title,
    String? description,
    String? assigneeId,
    String? dueAt,
  }) async {
    final user = ref.read(authProvider);
    if (user == null) return false;

    try {
      final result = await GroupChatService.sendTaskMessage(
        groupId: _groupId,
        senderId: user.id,
        title: title,
        description: description,
        assigneeId: assigneeId,
        dueAt: dueAt,
      );

      final message = ChatMessage.fromJson(result['message']);
      state = AsyncData([...state.asData?.value ?? [], message]);
      ref.invalidate(groupsNotifierProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() {
    loadMessages(_groupId, silent: false);
  }
}

final chatNotifierProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

// Helper: per-group chat provider using family
final groupChatProvider = FutureProvider.family<List<ChatMessage>, int>((
  ref,
  groupId,
) {
  return GroupChatService.getMessages(groupId);
});
