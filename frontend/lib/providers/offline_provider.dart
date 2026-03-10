import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/offline_queue_service.dart';

/// Provider for connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = ConnectivityService();
  return connectivity.connectionStatusStream;
});

/// Provider to check if device is online
final isOnlineProvider = Provider<bool>((ref) {
  return ConnectivityService().isOnline;
});

/// Provider for offline queue operations
final offlineQueueProvider = FutureProvider<List<OfflineOperation>>((
  ref,
) async {
  return await OfflineQueueService().getQueue();
});

/// Provider for pending tasks count
final pendingTasksCountProvider = FutureProvider<int>((ref) async {
  final queue = await OfflineQueueService().getQueue();
  return queue.where((op) => op.entityType == 'task').length;
});

enum SyncStatus { idle, syncing, success, error }
