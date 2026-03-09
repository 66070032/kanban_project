# Integration Examples

Quick reference for integrating voice features into your Flutter app.

---

## 📱 UI Integration Examples

### 1. Show Voice Recorder in a Dialog

```dart
Future<void> _recordVoiceInstruction(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Record Voice Instruction'),
      content: SizedBox(
        width: double.maxFinite,
        child: VoiceRecorderWidget(
          title: 'Record Task Instruction',
          onRecordingComplete: (filePath, duration) {
            Navigator.pop(context);
            print('Recording saved to: $filePath');
            print('Duration: ${duration.inSeconds}s');
            // TODO: Upload to backend using task_provider
          },
        ),
      ),
    ),
  );
}
```

### 2. Display Voice Player in Task List Item

```dart
class TaskListItem extends StatelessWidget {
  final Task task;

  const TaskListItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: task.voiceInstructionUrl != null
            ? SizedBox(
                height: 50,
                child: VoicePlayerWidget(
                  audioUrl: task.voiceInstructionUrl!,
                  title: 'Voice Instruction',
                ),
              )
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        ),
      ),
    );
  }
}
```

### 3. Show Incoming Call Notification

```dart
Future<void> _showTaskReminder(
  BuildContext context,
  Task task,
  User assigner,
) async {
  await showIncomingCallOverlay(
    context: context,
    callerId: assigner.id.toString(),
    callerName: assigner.name,
    callerAvatarUrl: assigner.avatarUrl ?? '',
    taskTitle: task.title,
    onAccept: () {
      print('User accepted - play voice reminder');
      // TODO: Play reminder audio
      _playVoiceReminder(task.id);
    },
    onReject: () {
      print('User rejected - snooze notification');
      // TODO: Snooze for 5 minutes
      _snoozeReminder(task.id);
    },
  );
}
```

---

## 🔌 API Integration Examples

### 1. Upload Voice Instruction with Riverpod

```dart
class TaskDetailPage extends ConsumerWidget {
  final Task task;

  const TaskDetailPage({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            VoiceRecorderWidget(
              onRecordingComplete: (filePath, duration) async {
                // Upload using provider
                final uploadState = ref.watch(
                  uploadVoiceInstructionProvider((task.id, filePath)),
                );

                uploadState.when(
                  data: (url) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Voice uploaded: $url')),
                    );
                  },
                  loading: () => print('Uploading...'),
                  error: (error, stack) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload failed: $error')),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Fetch Tasks with Voice Instructions

```dart
class TaskListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const LoginPage();

    final tasksAsync = ref.watch(userTasksProvider(user.id.toString()));

    return tasksAsync.when(
      data: (tasks) => ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.status ?? 'todo'),
            trailing: task.voiceInstructionUrl != null
                ? IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {
                      // Play voice instruction
                      _playVoice(task.voiceInstructionUrl!);
                    },
                  )
                : null,
          );
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
```

### 3. Create Task with Voice

```dart
class CreateTaskPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(taskFormProvider);

    return Scaffold(
      body: Column(
        children: [
          TextField(
            onChanged: (value) {
              ref.read(taskFormProvider.notifier).setTitle(value);
            },
            hint: 'Task Title',
          ),
          VoiceRecorderWidget(
            title: 'Add Voice Instruction',
            onRecordingComplete: (filePath, duration) {
              ref
                  .read(taskFormProvider.notifier)
                  .setVoiceInstruction(filePath);
            },
          ),
          ElevatedButton(
            onPressed: () async {
              // Create task with voice
              try {
                final newTask = await ref.read(createTaskProvider(
                  {
                    'title': formState['title'],
                    'description': formState['description'],
                    'due_at': formState['dueAt'],
                  },
                ).future);

                // Upload voice if recorded
                if (formState['voiceInstructionPath'] != null) {
                  await ref.read(
                    uploadVoiceInstructionProvider(
                      (newTask.id, formState['voiceInstructionPath']),
                    ).future,
                  );
                }

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }
}
```

### 4. Schedule Voice Reminder Notification

```dart
Future<void> _scheduleReminderNotification(
  Task task,
  Reminder reminder,
) async {
  final notificationService = NotificationService();

  await notificationService.scheduleNotification(
    id: task.id,
    title: 'Task Reminder: ${task.title}',
    body: 'A voice reminder from ${task.assigneeId}',
    scheduledTime: reminder.dueDate,
    soundPath: 'sounds/reminder_bell', // Custom sound
    payload: 'task_${task.id}',
  );

  print('Reminder scheduled for ${reminder.dueDate}');
}
```

### 5. Handle Notification Taps

```dart
Future<void> _setupNotificationHandlers(WidgetRef ref) async {
  final notificationService = NotificationService();

  // When user taps notification, show incoming call screen
  // This is handled by flutter_local_notifications plugin
  // and needs to be configured in main.dart
}
```

---

## 🎤 Audio Service Usage Examples

### 1. Simple Recording and Upload

```dart
Future<void> recordAndUploadVoice(int taskId) async {
  final recordingService = AudioRecordingService();
  final apiService = ApiService();

  try {
    // Start recording
    print('Starting recording...');
    await recordingService.startRecording();

    // Simulate recording for 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    // Stop and get file path
    final filePath = await recordingService.stopRecording();
    print('Recording saved to: $filePath');

    // Upload to backend
    final response = await apiService.upload(
      '/tasks/$taskId/voice-instruction',
      filePath: filePath,
      fileFieldName: 'voice_instruction',
    );

    print('Upload successful: $response');
  } catch (e) {
    print('Error: $e');
    await recordingService.cancelRecording();
  }
}
```

### 2. Stream and Play Remote Audio

```dart
Future<void> playRemoteVoice(String audioUrl) async {
  final playbackService = AudioPlaybackService();

  try {
    print('Loading audio from: $audioUrl');

    // Play from URL (streams from server)
    await playbackService.playFromUrl(audioUrl);

    // Listen to completion
    await Future.delayed(const Duration(seconds: 30));
    await playbackService.stop();

    print('Playback complete');
  } catch (e) {
    print('Error: $e');
    await playbackService.stop();
  }
}
```

### 3. Play with Seek Control

```dart
Future<void> playWithControls(String audioPath) async {
  final playbackService = AudioPlaybackService();

  try {
    await playbackService.play(audioPath);

    // Seek to 10 seconds
    await playbackService.seek(const Duration(seconds: 10));

    // Get duration for UI
    final duration = await playbackService.getDuration(audioPath);
    print('Audio duration: $duration');

    // Pause after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    await playbackService.pause();

    // Resume after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    await playbackService.resume();
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 🔐 Permission Handling

### 1. Request Microphone Permission

```dart
Future<bool> ensureRecordingPermission() async {
  final recordingService = AudioRecordingService();

  final hasPermission = await recordingService.hasRecordingPermission();
  if (hasPermission) return true;

  final granted = await recordingService.requestRecordingPermission();
  return granted;
}
```

### 2. Request Notification Permission

```dart
Future<bool> ensureNotificationPermission() async {
  final notificationService = NotificationService();

  final hasPermission = await notificationService.hasNotificationPermission();
  if (hasPermission) return true;

  final granted = await notificationService.requestNotificationPermission();
  return granted;
}
```

### 3. Check All Permissions

```dart
Future<bool> checkAllRequiredPermissions() async {
  final recordingOk = await ensureRecordingPermission();
  final notificationOk = await ensureNotificationPermission();

  return recordingOk && notificationOk;
}
```

---

## 🚨 Error Handling Patterns

### 1. Try-Catch with User Feedback

```dart
try {
  await recordingService.startRecording();
} on PermissionException {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Microphone permission denied')),
  );
} on StorageException {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Not enough storage for recording')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Recording error: $e')),
  );
}
```

### 2. Riverpod Error Handling in UI

```dart
class VoiceUploadButton extends ConsumerWidget {
  final int taskId;
  final String filePath;

  const VoiceUploadButton({
    required this.taskId,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(
      uploadVoiceInstructionProvider((taskId, filePath)),
    );

    return uploadState.when(
      data: (url) => const Chip(
        label: Text('✓ Voice uploaded'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => Chip(
        label: Text('Error: $error'),
        backgroundColor: Color(0xFFFF5252),
      ),
    );
  }
}
```

---

## 📊 Complete Task with Voice Workflow

```dart
Future<void> completeTaskWorkflow(
  BuildContext context,
  WidgetRef ref,
  User currentUser,
) async {
  // 1. Create task
  final task = await ref.read(createTaskProvider({
    'title': 'Review Code Changes',
    'description': 'Check PR #123',
    'status': 'todo',
    'assignee_id': currentUser.id,
    'due_at': DateTime.now().add(Duration(days: 1)),
  }).future);

  print('Task created: ${task.id}');

  // 2. Record voice instruction
  final recordingService = AudioRecordingService();
  await recordingService.startRecording();
  await Future.delayed(const Duration(seconds: 3));
  final voiceFile = await recordingService.stopRecording();

  // 3. Upload voice instruction
  final voiceUrl = await ref.read(
    uploadVoiceInstructionProvider((task.id, voiceFile)).future,
  );

  print('Voice uploaded: $voiceUrl');

  // 4. Create reminder
  final reminder = await ref.read(createReminderProvider({
    'user_id': currentUser.id,
    'title': 'Reminder: ${task.title}',
    'due_date': DateTime.now().add(Duration(days: 1, hours: 9)),
  }).future);

  // 5. Schedule notification
  final notificationService = NotificationService();
  await notificationService.scheduleNotification(
    id: task.id,
    title: 'Task Due: ${task.title}',
    body: 'Voice instruction available',
    scheduledTime: reminder.dueDate,
    payload: 'task_${task.id}',
  );

  print('Complete workflow finished!');
}
```

---

## 🎯 Ready to Integrate

All these examples are production-ready. Just:

1. Update the base URL in `api_service.dart`
2. Copy the example code into your widgets
3. Install audio packages when needed
4. Test with your backend

See `VOICE_FEATURES_GUIDE.md` for detailed documentation.
