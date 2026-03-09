import 'package:flutter/material.dart';

/// Incoming Call Screen
/// Simulates an incoming phone call notification UI for task reminders
class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String callerAvatarUrl;
  final String taskTitle;
  final Function onAccept;
  final Function onReject;
  final Duration autoRejectAfter;

  const IncomingCallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callerAvatarUrl,
    required this.taskTitle,
    required this.onAccept,
    required this.onReject,
    this.autoRejectAfter = const Duration(seconds: 30),
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Setup countdown
    _countdownController =
        AnimationController(duration: widget.autoRejectAfter, vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _handleReject();
            }
          })
          ..forward();

    // Update countdown display every second
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    _pulseController.stop();
    _countdownController.stop();

    // Close overlay and call callback
    if (mounted) {
      Navigator.pop(context);
    }
    widget.onAccept();
  }

  Future<void> _handleReject() async {
    _pulseController.stop();
    _countdownController.stop();

    // Close overlay and call callback
    if (mounted) {
      Navigator.pop(context);
    }
    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section - Caller info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing avatar
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: 1,
                      end: 1.1,
                    ).animate(_pulseController),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyan[400]!, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.cyan[400],
                        child: Text(
                          widget.callerName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Caller name
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Task title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Task: ${widget.taskTitle}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Countdown timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Auto-reject in ${_secondsRemaining}s',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom section - Call actions
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  GestureDetector(
                    onTap: _handleReject,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF3B30),
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Accept button
                  GestureDetector(
                    onTap: _handleAccept,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF34C759),
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show incoming call screen as overlay
Future<void> showIncomingCallOverlay({
  required BuildContext context,
  required String callerId,
  required String callerName,
  required String callerAvatarUrl,
  required String taskTitle,
  required Function onAccept,
  required Function onReject,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => IncomingCallScreen(
        callerId: callerId,
        callerName: callerName,
        callerAvatarUrl: callerAvatarUrl,
        taskTitle: taskTitle,
        onAccept: onAccept,
        onReject: onReject,
      ),
      fullscreenDialog: true,
    ),
  );
}
