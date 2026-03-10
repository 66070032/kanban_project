/// Example: Enhanced Task Creation with Offline Support
///
/// This shows how to update existing widgets to use the new error handling
/// and offline support features.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Example NOT RUN - for documentation purposes only

// ============================================================================
// EXAMPLE 1: Simple Form with Offline Support
// ============================================================================

class TaskFormExample extends ConsumerStatefulWidget {
const TaskFormExample({Key? key}) : super(key: key);

@override
ConsumerState<TaskFormExample> createState() => \_TaskFormExampleState();
}

class \_TaskFormExampleState extends ConsumerState<TaskFormExample> {
final titleController = TextEditingController();
bool isSubmitting = false;

@override
void initState() {
super.initState();

    // Listen to connectivity changes
    ref.read(connectivityProvider).listen(
      (previous, next) => _onConnectivityChanged(next),
    );

}

void \_onConnectivityChanged(AsyncValue<bool> connectivity) {
connectivity.whenData((isOnline) {
if (isOnline) {
// Connection restored - sync queued operations
\_syncOfflineQueue();
}
});
}

Future<void> \_syncOfflineQueue() async {
try {
// This will automatically retry all queued operations
await ApiService().retrySyncQueue();

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Synced offline changes!',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }

}

Future<void> \_submitTask() async {
if (titleController.text.isEmpty) {
ErrorHandler.showWarningSnackBar(
context,
'Please enter a task title',
);
return;
}

    setState(() => isSubmitting = true);

    try {
      final api = ApiService();

      // This will automatically queue if offline
      await api.post(
        '/tasks',
        body: {
          'title': titleController.text,
          'description': '',
          'status': 'todo',
        },
        allowOffline: true, // Allow offline operation
      );

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Task created!');
        titleController.clear();
        Navigator.pop(context);
      }
    } on OfflineException catch (e) {
      if (mounted) {
        // Friendly offline message
        ErrorHandler.showWarningSnackBar(context, e.message);
      }
    } on UnauthorizedException {
      if (mounted) {
        // User needs to login again
        ErrorHandler.showErrorSnackBar(context, Error);
        // TODO: Redirect to login screen
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('New Task')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
// Connectivity indicator
Consumer(
builder: (context, ref, \_) {
final isOnline = ref.watch(isOnlineProvider);
return Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isOnline ? Colors.green[50] : Colors.orange[50],
border: Border.all(
color: isOnline ? Colors.green : Colors.orange,
),
borderRadius: BorderRadius.circular(8),
),
child: Row(
children: [
Icon(
isOnline ? Icons.cloud_done : Icons.cloud_off,
color: isOnline ? Colors.green : Colors.orange,
),
const SizedBox(width: 8),
Text(
isOnline ? 'Online' : 'Offline - Changes will sync',
style: TextStyle(
color: isOnline ? Colors.green[700] : Colors.orange[700],
),
),
],
),
);
},
),
const SizedBox(height: 16),

            // Title input
            TextField(
              controller: titleController,
              enabled: !isSubmitting,
              decoration: InputDecoration(
                hintText: 'Enter task title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: isSubmitting ? null : _submitTask,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Task'),
            ),
          ],
        ),
      ),
    );

}

@override
void dispose() {
titleController.dispose();
super.dispose();
}
}

// ============================================================================
// EXAMPLE 2: List with Offline Indicator and Pending Count
// ============================================================================

class TaskListExample extends ConsumerWidget {
const TaskListExample({Key? key}) : super(key: key);

@override
Widget build(BuildContext context, WidgetRef ref) {
final isOnline = ref.watch(isOnlineProvider);
final pendingCount = ref.watch(pendingTasksCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          // Show pending sync count
          pendingCount.whenData(
            (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '$count pending',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity banner
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Changes will sync when connection is restored.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),

          // Tasks list
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Your task count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Task ${index + 1}'),
                  trailing: isOnline
                      ? null
                      : const Icon(Icons.hourglass_empty, size: 18),
                );
              },
            ),
          ),
        ],
      ),
    );

}
}

// ============================================================================
// EXAMPLE 3: Data Fetching with Error Handling
// ============================================================================

class TasksScreenExample extends ConsumerStatefulWidget {
const TasksScreenExample({Key? key}) : super(key: key);

@override
ConsumerState<TasksScreenExample> createState() => \_TasksScreenExampleState();
}

class \_TasksScreenExampleState extends ConsumerState<TasksScreenExample> {
@override
void didChangeDependencies() {
super.didChangeDependencies();

    // Listen to connectivity and refresh when back online
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isOnline) {
        if (isOnline && previous?.value == false) {
          // Connection restored - refresh data
          ref.invalidate(userTasksProvider); // Your task provider
        }
      });
    });

}

@override
Widget build(BuildContext context) {
return Consumer(
builder: (context, ref, \_) {
final tasksAsync = ref.watch(userTasksProvider); // Your task provider

        return tasksAsync.when(
          data: (tasks) => ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => TaskTile(task: tasks[index]),
          ),

          loading: () => const Center(child: CircularProgressIndicator()),

          error: (error, stack) {
            // Handle different error types
            if (error is NetworkException) {
              return ErrorRetryWidget(
                error: error,
                onRetry: () => ref.invalidate(userTasksProvider),
              );
            }

            return ErrorDisplay(error: error);
          },
        );
      },
    );

}
}

// ============================================================================
// EXAMPLE 4: Error Display Widgets
// ============================================================================

class ErrorRetryWidget extends StatelessWidget {
final dynamic error;
final VoidCallback onRetry;

const ErrorRetryWidget({
Key? key,
required this.error,
required this.onRetry,
}) : super(key: key);

@override
Widget build(BuildContext context) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.error_outline,
size: 64,
color: Colors.red[300],
),
const SizedBox(height: 16),
Text(
ErrorHandler.getErrorTitle(error),
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
ErrorHandler.getErrorMessage(error),
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 14),
),
const SizedBox(height: 24),
ElevatedButton.icon(
onPressed: onRetry,
icon: const Icon(Icons.refresh),
label: const Text('Retry'),
),
],
),
);
}
}

class ErrorDisplay extends StatelessWidget {
final dynamic error;

const ErrorDisplay({Key? key, required this.error}) : super(key: key);

@override
Widget build(BuildContext context) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.error_outline,
size: 64,
color: Colors.red[300],
),
const SizedBox(height: 16),
Text(ErrorHandler.getErrorTitle(error)),
const SizedBox(height: 8),
Text(
ErrorHandler.getErrorMessage(error),
textAlign: TextAlign.center,
),
],
),
);
}
}

// ============================================================================
// EXAMPLE 5: Provider Setup (Add to your providers file)
// ============================================================================

/\*
// Add these to your task_provider.dart or similar:

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/task_model.dart';
import '../services/error_handler_service.dart';

final userTasksProvider = FutureProvider.family<List<Task>, String>((ref, userId) async {
try {
final api = ApiService();
final data = await api.get('/tasks/assignee/$userId');
final List<dynamic> tasks = data;
return tasks.map((t) => Task.fromJson(t)).toList();
} on NetworkException {
rethrow;
} catch (e) {
throw AppException(message: 'Failed to load tasks');
}
});
\*/

// ============================================================================
// IMPORTS (Add these to your files)
// ============================================================================

/_
import '../services/api_service.dart';
import '../services/error_handler_service.dart';
import '../services/connectivity_service.dart';
import '../providers/offline_provider.dart';
_/
