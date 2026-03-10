import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../core/config/app_config.dart';
import 'error_handler_service.dart';
import 'connectivity_service.dart';
import 'offline_queue_service.dart';

/// Centralized HTTP service - all API calls should go through here.
/// Includes offline support, automatic retries, and comprehensive error handling.
class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static final ApiService _instance = ApiService._internal();
  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineQueueService _offlineQueue = OfflineQueueService();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _connectivity.initialize();
  }

  /// Check if device is online
  bool get isOnline => _connectivity.isOnline;

  /// Get connectivity stream
  Stream<bool> get connectivityStream => _connectivity.connectionStatusStream;

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    bool allowOffline = false,
  }) async {
    if (!isOnline) {
      throw NetworkException(
        message: 'No internet connection. Please check your network.',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers ?? {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException(message: 'Request timeout. Please try again.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Network error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool allowOffline = false,
  }) async {
    if (!isOnline) {
      if (allowOffline) {
        // Queue the operation for later sync
        await _queueOperation('create', endpoint, body ?? {});
        throw OfflineException(
          message:
              'You are offline. Your changes will sync when connection is restored.',
        );
      }
      throw NetworkException(
        message: 'No internet connection. Please check your network.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on TimeoutException {
      if (allowOffline) {
        await _queueOperation('create', endpoint, body ?? {});
      }
      throw NetworkException(message: 'Request timeout. Please try again.');
    } catch (e) {
      if (e is AppException) rethrow;
      if (allowOffline) {
        await _queueOperation('create', endpoint, body ?? {});
      }
      throw NetworkException(
        message: 'Network error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool allowOffline = false,
  }) async {
    if (!isOnline) {
      if (allowOffline) {
        await _queueOperation('update', endpoint, body ?? {});
        throw OfflineException();
      }
      throw NetworkException(
        message: 'No internet connection. Please check your network.',
      );
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on TimeoutException {
      if (allowOffline) {
        await _queueOperation('update', endpoint, body ?? {});
      }
      throw NetworkException(message: 'Request timeout. Please try again.');
    } catch (e) {
      if (e is AppException) rethrow;
      if (allowOffline) {
        await _queueOperation('update', endpoint, body ?? {});
      }
      throw NetworkException(
        message: 'Network error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool allowOffline = false,
  }) async {
    if (!isOnline) {
      if (allowOffline) {
        await _queueOperation('delete', endpoint, {});
        throw OfflineException();
      }
      throw NetworkException(
        message: 'No internet connection. Please check your network.',
      );
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers ?? {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on TimeoutException {
      if (allowOffline) {
        await _queueOperation('delete', endpoint, {});
      }
      throw NetworkException(message: 'Request timeout. Please try again.');
    } catch (e) {
      if (e is AppException) rethrow;
      if (allowOffline) {
        await _queueOperation('delete', endpoint, {});
      }
      throw NetworkException(
        message: 'Network error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Upload file with multipart form data
  Future<dynamic> upload(
    String endpoint, {
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
  }) async {
    if (!isOnline) {
      throw NetworkException(
        message: 'Cannot upload while offline. Please check your network.',
      );
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );

      // Add additional fields
      if (additionalFields != null) {
        additionalFields.forEach((key, value) {
          request.fields[key] = value;
        });
      }

      // Add headers
      if (headers != null) {
        request.headers.addAll(headers);
      }

      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw ServerException(
          message: 'Upload failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw NetworkException(message: 'Upload timeout. Please try again.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Upload error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty ? {} : jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else if (response.statusCode == 404) {
      throw ServerException(message: 'Resource not found', statusCode: 404);
    } else if (response.statusCode == 400) {
      throw ValidationException(message: 'Bad request: ${response.body}');
    } else if (response.statusCode >= 500) {
      throw ServerException(
        message: 'Server error. Please try again later.',
        statusCode: response.statusCode,
      );
    } else {
      throw ServerException(
        message: 'Error ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Queue an operation for offline syncing
  Future<void> _queueOperation(
    String operationType,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      // Determine entity type from endpoint
      final entityType = _extractEntityType(endpoint);

      final operation = OfflineOperation(
        id: '${operationType}_${endpoint}_${DateTime.now().millisecondsSinceEpoch}',
        operationType: operationType,
        entityType: entityType,
        data: data,
        createdAt: DateTime.now(),
      );

      await _offlineQueue.addOperation(operation);
    } catch (e) {
      print('Error queuing operation: $e');
    }
  }

  /// Extract entity type from API endpoint
  String _extractEntityType(String endpoint) {
    if (endpoint.contains('/tasks')) return 'task';
    if (endpoint.contains('/reminders')) return 'reminder';
    if (endpoint.contains('/groups')) return 'group';
    if (endpoint.contains('/users')) return 'user';
    return 'unknown';
  }

  /// Retry all queued operations when connection is restored
  Future<void> retrySyncQueue() async {
    if (!isOnline) return;

    try {
      final operations = await _offlineQueue.getRetryableOperations();

      for (final operation in operations) {
        try {
          await _retryOperation(operation);
          await _offlineQueue.removeOperation(operation.id);
        } catch (e) {
          await _offlineQueue.incrementRetryCount(operation.id);
          print('Retry failed for ${operation.id}: $e');
        }
      }
    } catch (e) {
      print('Error retrying sync queue: $e');
    }
  }

  /// Retry a single operation
  Future<void> _retryOperation(OfflineOperation operation) async {
    switch (operation.operationType) {
      case 'create':
        await post(operation.data['endpoint'] ?? '', body: operation.data);
        break;
      case 'update':
        await put(operation.data['endpoint'] ?? '', body: operation.data);
        break;
      case 'delete':
        await delete(operation.data['endpoint'] ?? '');
        break;
    }
  }

  /// Clean up resources
  void dispose() {
    _connectivity.dispose();
  }
}
