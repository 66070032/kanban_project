import 'dart:async';
import 'dart:io';

/// Simpler connectivity check using basic network requests
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  Timer? _checkTimer;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  /// Get the stream of connectivity changes
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Check if device is currently online
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  /// Uses periodic checking since connectivity_plus might not be installed
  Future<void> initialize() async {
    // Initial check
    await _checkConnectivity();

    // Periodic checks every 10 seconds
    _checkTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Perform connectivity check via DNS lookup
  Future<void> _checkConnectivity() async {
    try {
      final wasOnline = _isOnline;

      // Try to resolve a reliable host (Google DNS)
      final result = await InternetAddress.lookup('google.com');

      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (wasOnline != _isOnline) {
        _connectionStatusController.add(_isOnline);
      }
    } catch (_) {
      final wasOnline = _isOnline;
      _isOnline = false;

      if (wasOnline != _isOnline) {
        _connectionStatusController.add(_isOnline);
      }
    }
  }

  /// Clean up resources
  void dispose() {
    _checkTimer?.cancel();
    _connectionStatusController.close();
  }
}
