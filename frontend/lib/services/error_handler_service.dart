import 'package:flutter/material.dart';
import 'dart:async';

/// Custom exceptions for better error handling
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({required this.message, this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    String message = 'Network error. Please check your connection.',
    dynamic originalError,
  }) : super(
         message: message,
         code: 'NETWORK_ERROR',
         originalError: originalError,
       );
}

class OfflineException extends AppException {
  OfflineException({
    String message =
        'You are offline. Changes will sync when connection is restored.',
    dynamic originalError,
  }) : super(
         message: message,
         code: 'OFFLINE_ERROR',
         originalError: originalError,
       );
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    dynamic originalError,
  }) : super(
         message: message,
         code: 'SERVER_ERROR',
         originalError: originalError,
       );
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    String message = 'Unauthorized. Please login again.',
    dynamic originalError,
  }) : super(
         message: message,
         code: 'UNAUTHORIZED',
         originalError: originalError,
       );
}

class ValidationException extends AppException {
  ValidationException({required String message, dynamic originalError})
    : super(
        message: message,
        code: 'VALIDATION_ERROR',
        originalError: originalError,
      );
}

/// Handles errors and provides user-friendly messages
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is TimeoutException) {
      return 'Request timeout. Please try again.';
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused')) {
      return 'Network error. Please check your connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String getErrorTitle(dynamic error) {
    if (error is NetworkException) {
      return 'Network Error';
    }
    if (error is OfflineException) {
      return 'Offline Mode';
    }
    if (error is ServerException) {
      return 'Server Error';
    }
    if (error is UnauthorizedException) {
      return 'Authentication Error';
    }
    if (error is ValidationException) {
      return 'Validation Error';
    }
    return 'Error';
  }

  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = getErrorMessage(error);
    final title = getErrorTitle(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
