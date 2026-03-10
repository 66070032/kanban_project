# Error Handling & Offline Support Guide

## Overview

This guide documents the comprehensive error handling and offline support system implemented for the Kanban Task Manager Flutter app.

## Architecture

### New Services Created

#### 1. **ConnectivityService** (`connectivity_service.dart`)

- Monitors network connectivity in real-time
- Provides a stream of connectivity changes
- Singleton pattern for app-wide access
- Auto-initializes on app startup

**Usage:**

```dart
final connectivity = ConnectivityService();
final isOnline = connectivity.isOnline;

// Listen to connectivity changes
connectivity.connectionStatusStream.listen((isOnline) {
  print('Online: $isOnline');
});
```

#### 2. **ErrorHandlerService** (`error_handler_service.dart`)

Provides custom exception types and user-friendly error messages:

**Exception Types:**

- `AppException` - Base exception
- `NetworkException` - Network/connectivity errors
- `OfflineException` - Specifically for offline state
- `ServerException` - Server-side errors (50x)
- `UnauthorizedException` - Auth failures (401)
- `ValidationException` - Invalid input (400)

**Usage:**

```dart
try {
  // API call
} catch (e) {
  ErrorHandler.showErrorSnackBar(context, e);
}

// Custom error messages
String message = ErrorHandler.getErrorMessage(error);
String title = ErrorHandler.getErrorTitle(error);

// Success notifications
ErrorHandler.showSuccessSnackBar(context, 'Task created!');
ErrorHandler.showWarningSnackBar(context, 'Warning message');
```

#### 3. **OfflineQueueService** (`offline_queue_service.dart`)

Manages operations queue for syncing when connection is restored:

**Features:**

- Stores offline operations in SharedPreferences
- Tracks retry attempts (max 3 retries)
- Supports create, update, delete operations
- Organized by entity type (task, reminder, group, user)

**Usage:**

```dart
final queue = OfflineQueueService();

// Add operation to queue
await queue.addOperation(operation);

// Get all pending operations
final operations = await queue.getQueue();

// Get pending items by type
final pendingTasks = await queue.getPendingTasks();

// Get retryable operations (not exceeded max retries)
final retryable = await queue.getRetryableOperations();

// Check queue length
final count = await queue.getQueueLength();
```

#### 4. **APIService Enhancement** (`api_service.dart`)

Completely refactored with:

- Automatic connectivity checking
- Offline operation queuing
- Comprehensive error handling
- Automatic retry mechanism for queued operations

**Usage:**

```dart
final api = ApiService();

// Check connectivity
bool isOnline = api.isOnline;

// Listen to connectivity changes
api.connectivityStream.listen((isOnline) {
  print('Connection: $isOnline');
});

// All requests now include:
// - Connectivity check
// - Automatic offline queueing (if allowOffline=true)
// - Better error handling

// Example: GET request
try {
  final data = await api.get('/endpoint');
} on NetworkException {
  // Handle network error
} on OfflineException {
  // Handle offline mode
}

// Example: POST with offline support
try {
  final data = await api.post(
    '/tasks',
    body: {'title': 'New Task'},
    allowOffline: true, // Queue if offline
  );
} on OfflineException {
  // Show user operation will sync when online
}

// Retry sync queue when connection restored
await api.retrySyncQueue();
```

#### 5. **Background Sync Refactoring** (`background_sync_service.dart`)

Reduced from 600 lines to ~150 lines by splitting into:

- `TaskSyncService` - Handles task syncing
- `ReminderSyncService` - Handles reminder syncing
- `MessageSyncService` - Handles group message syncing

Each service is independently testable and maintainable.

### Providers

#### **OfflineProvider** (`providers/offline_provider.dart`)

Riverpod providers for offline functionality:

```dart
// Check if online
final isOnline = ref.watch(isOnlineProvider);

// Listen to connectivity stream
final isConnected = ref.watch(connectivityProvider);

// Get offline queue
final queue = ref.watch(offlineQueueProvider);

// Get pending tasks count
final pendingCount = ref.watch(pendingTasksCountProvider);

// Sync status
final syncStatus = ref.watch(syncStatusProvider);
```

## Error Handling Flow

### Request Processing

```
1. Check connectivity (ConnectivityService)
   ↓
2. If offline + allowOffline=true → Queue operation (OfflineQueueService)
   ↓
3. If offline + allowOffline=false → Throw NetworkException
   ↓
4. Always add timeout (30s for normal, 60s for uploads)
   ↓
5. Handle response with proper exception types
   ↓
6. Check status code:
   - 2xx → Return JSON
   - 401 → UnauthorizedException
   - 400 → ValidationException
   - 404 → ServerException (not found)
   - 5xx → ServerException (server error)
   - Other → Generic ServerException
```

### Error Display to User

```dart
ErrorHandler.showErrorSnackBar(context, error);

// Different titles based on error type:
// - NetworkException → "Network Error"
// - OfflineException → "Offline Mode"
// - ServerException → "Server Error"
// - UnauthorizedException → "Authentication Error"
// - ValidationException → "Validation Error"
```

## Offline Support Implementation

### How Offline Operations Work

1. **Operation Initiated** → Check connectivity
2. **If Offline** → Store operation in queue (OfflineQueueService)
3. **Show Alert** → "Changes will sync when connection restored"
4. **Connection Restored** → Detect via ConnectivityService
5. **Auto-Retry** → Attempt to execute queued operations
6. **Max Retries** → After 3 failed attempts, stop retrying

### Implementation in UI

```dart
class TaskForm extends ConsumerWidget {
  Future<void> _submitTask(WidgetRef ref) async {
    try {
      final api = ApiService();

      // This will automatically queue if offline
      await api.post(
        '/tasks',
        body: taskData,
        allowOffline: true,
      );

      ErrorHandler.showSuccessSnackBar(context, 'Task saved!');
    } on OfflineException catch (e) {
      ErrorHandler.showWarningSnackBar(context, e.message);
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }
}
```

### Detecting Connection Restoration

```dart
void initState() {
  super.initState();

  // Listen to connectivity changes
  ConnectivityService().connectionStatusStream.listen((isOnline) {
    if (isOnline) {
      // Connection restored - retry sync
      _applySyncQueue();
    }
  });
}

Future<void> _applySyncQueue() async {
  try {
    await ApiService().retrySyncQueue();
    ErrorHandler.showSuccessSnackBar(context, 'Synced offline changes!');
  } catch (e) {
    ErrorHandler.showErrorSnackBar(context, e);
  }
}
```

## Code Organization

### Before (God File)

- `background_sync_service.dart`: 600+ lines
- All sync logic mixed together
- Hard to test individual parts
- Difficult to modify specific sync behavior

### After (Modular)

```
services/
├── background_sync_service.dart      (~150 lines, orchestrator only)
├── task_sync_service.dart             (~150 lines, task-specific)
├── reminder_sync_service.dart         (~150 lines, reminder-specific)
├── message_sync_service.dart          (~100 lines, message-specific)
├── connectivity_service.dart          (~50 lines, connectivity only)
├── error_handler_service.dart         (~200 lines, error handling)
├── offline_queue_service.dart         (~200 lines, queue management)
├── api_service.dart                   (~250 lines, enhanced with offline support)
└── [other existing services...]
```

## Best Practices

### 1. **Always Use ErrorHandler**

```dart
// ❌ Bad
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text(error.toString()),
));

// ✅ Good
ErrorHandler.showErrorSnackBar(context, error);
```

### 2. **Set `allowOffline=true` for User-Generated Content**

```dart
// ❌ Bad - Users can't create tasks offline
await api.post('/tasks', body: data);

// ✅ Good - Tasks queue for later sync
await api.post('/tasks', body: data, allowOffline: true);
```

### 3. **Handle Specific Exceptions**

```dart
// ❌ Bad
try {
  await api.get('/endpoint');
} catch (e) {
  print('Error: $e');
}

// ✅ Good
try {
  await api.get('/endpoint');
} on OfflineException {
  // Show "changes will sync" message
} on UnauthorizedException {
  // Redirect to login
} on ServerException {
  // Show retry button
} catch (e) {
  ErrorHandler.showErrorSnackBar(context, e);
}
```

### 4. **Use Providers for Connectivity**

```dart
// Instead of directly checking ConnectivityService
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return isOnline
        ? const OnlineContent()
        : const OfflineContent();
  }
}
```

## Testing Offline Functionality

### Testing Scenarios

1. **No Internet** → Toggle airplane mode
2. **Slow Network** → Throttle in DevTools
3. **Network Timeout** → Emulate network issue
4. **Connection Loss During Sync** → Toggle network mid-operation
5. **App Restart While Offline** → Force stop + reopen

### Debugging

```dart
// Check queue status
final queue = await OfflineQueueService().getQueue();
print('Pending operations: ${queue.length}');

// Check connectivity
print('Is online: ${ConnectivityService().isOnline}');

// Monitor sync retries
ApiService().retrySyncQueue().then((_) {
  print('Retry complete');
});
```

## Migration Guide

### For Existing API Calls

**Old:**

```dart
final res = await http.get(Uri.parse('$baseUrl/tasks'));
final tasks = jsonDecode(res.body);
```

**New:**

```dart
final api = ApiService();
try {
  final tasks = await api.get('/tasks');
} on NetworkException {
  // Handle errors
} on OfflineException {
  // Handle offline
}
```

### For UI Error Handling

**Old:**

```dart
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString()))
  );
}
```

**New:**

```dart
catch (e) {
  ErrorHandler.showErrorSnackBar(context, e);
}
```

### For Forms with Offline Support

**Old:**

```dart
await api.post('/tasks', body: taskData);
```

**New:**

```dart
await api.post('/tasks', body: taskData, allowOffline: true);
```

## Dependencies Added

- `connectivity_plus`: Network connectivity detection
- `flutter_riverpod`: State management (already used)
- `shared_preferences`: Local storage (already used)

## Future Enhancements

1. **Automatic Background Sync** - Sync queue automatically when online
2. **Sync Progress Indicator** - Show progress of syncing operations
3. **Conflict Resolution** - Handle conflicts when offline data conflicts with server
4. **Data Compression** - Compress queue data for large offline operations
5. **Selective Sync** - Let users choose which operations to sync
6. **Analytics** - Track offline usage patterns
