import 'package:flutter/material.dart';

/// Voice Recorder Widget
/// Reusable widget for recording voice instructions and reminders
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, Duration duration)? onRecordingComplete;
  final String title;
  final Color accentColor;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.title = 'Record Voice',
    this.accentColor = const Color(0xFF00BCD4),
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordedFilePath;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _stopwatch.start();

      // TODO: Implement actual recording with 'record' package
      // final recordService = AudioRecordingService();
      // _recordedFilePath = await recordService.startRecording();

      // Update duration display
      while (_isRecording) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _recordingDuration = _stopwatch.elapsed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recording error: $e')));
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _stopwatch.stop();

      setState(() {
        _isRecording = false;
        _recordingDuration = _stopwatch.elapsed;
      });

      // TODO: Implement actual stop recording
      // final recordService = AudioRecordingService();
      // _recordedFilePath = await recordService.stopRecording();

      // Callback to parent
      if (_recordedFilePath != null) {
        widget.onRecordingComplete?.call(
          _recordedFilePath!,
          _recordingDuration,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _stopwatch.stop();
      _stopwatch.reset();

      setState(() {
        _isRecording = false;
        _recordedFilePath = null;
        _recordingDuration = Duration.zero;
      });

      // TODO: Implement cancel recording
      // final recordService = AudioRecordingService();
      // await recordService.cancelRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling recording: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isRecording ? widget.accentColor : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _isRecording
            ? widget.accentColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (_isRecording)
            Column(
              children: [
                Icon(Icons.mic, size: 48, color: widget.accentColor),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(_recordingDuration),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _cancelRecording,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text('Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
