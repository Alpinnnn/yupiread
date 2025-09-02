import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  static ErrorHandlerService get instance => _instance;
  ErrorHandlerService._internal();

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
    Duration delay = retryDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempts++;

        if (kDebugMode) {
          print('Operation failed (attempt $attempts/$maxAttempts): $error');
        }

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          break;
        }

        // Don't retry on final attempt
        if (attempts >= maxAttempts) {
          break;
        }

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    throw ErrorHandlerException(
      'Operation failed after $attempts attempts',
      originalError: lastError,
      attempts: attempts,
    );
  }

  bool shouldRetryError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;
    if (error is FileSystemException) {
      // Retry on temporary file system issues
      return error.osError?.errorCode == 32 || // File in use
          error.osError?.errorCode == 5; // Access denied
    }
    return false;
  }

  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      _logError(error, stackTrace, context);

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  void _logError(dynamic error, StackTrace stackTrace, String? context) {
    if (kDebugMode) {
      print('Error${context != null ? ' in $context' : ''}: $error');
      print('Stack trace: $stackTrace');
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: AppLocalizations.of(context).ok,
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void showRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRetry,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
    );
  }

  String getErrorMessage(BuildContext context, dynamic error) {
    if (error is ErrorHandlerException) {
      return error.message;
    }

    if (error is SocketException) {
      return AppLocalizations.of(context).noInternetConnection;
    }

    if (error is TimeoutException) {
      return 'Operasi timeout, silakan coba lagi';
    }

    if (error is FileSystemException) {
      switch (error.osError?.errorCode) {
        case 2:
          return AppLocalizations.of(context).fileNotFound;
        case 5:
          return AppLocalizations.of(context).accessDenied;
        case 32:
          return AppLocalizations.of(context).fileInUse;
        default:
          return AppLocalizations.of(context).fileSystemError;
      }
    }

    if (error is FormatException) {
      return AppLocalizations.of(context).invalidDataFormat;
    }

    return AppLocalizations.of(context).errorOccurredWith(error.toString());
  }
}

class ErrorHandlerException implements Exception {
  final String message;
  final dynamic originalError;
  final int attempts;

  ErrorHandlerException(this.message, {this.originalError, this.attempts = 1});

  @override
  String toString() {
    return 'ErrorHandlerException: $message (after $attempts attempts)';
  }
}

// Mixin for widgets that need error handling
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;

  Future<R> executeWithRetry<R>(
    Future<R> Function() operation, {
    R? fallbackValue,
    String? context,
  }) async {
    try {
      return await _errorHandler.executeWithRetry(
        operation,
        shouldRetry: _errorHandler.shouldRetryError,
      );
    } catch (error) {
      if (mounted) {
        _errorHandler.showErrorSnackBar(
          this.context,
          _errorHandler.getErrorMessage(this.context, error),
        );
      }

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  void showError(String message) {
    if (mounted) {
      _errorHandler.showErrorSnackBar(context, message);
    }
  }

  void showRetryDialog({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    if (mounted) {
      _errorHandler.showRetryDialog(
        context,
        title: title,
        message: message,
        onRetry: onRetry,
      );
    }
  }
}
