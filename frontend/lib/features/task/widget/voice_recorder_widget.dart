import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Voice Recorder Widget  uses the `record` package for real microphone input.
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
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordedFilePath;
  late Stopwatch _stopwatch;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _stopwatch.stop();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );

      _stopwatch.reset();
      _stopwatch.start();

      _durationTimer =
          Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted && _isRecording) {
          setState(() => _recordingDuration = _stopwatch.elapsed);
        }
      });

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Recording error: $e')));
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _durationTimer?.cancel();
      _stopwatch.stop();

      final path = await _recorder.stop();

      setState(() {
        _isRecording = false;
        _recordingDuration = _stopwatch.elapsed;
        _recordedFilePath = path;
      });

      if (path != null) {
        widget.onRecordingComplete?.call(path, _stopwatch.elapsed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _durationTimer?.cancel();
      _stopwatch.stop();
      _stopwatch.reset();
      await _recorder.cancel();
      setState(() {
        _isRecording = false;
        _recordedFilePath = null;
        _recordingDuration = Duration.zero;
      });
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
            ? widget.accentColor.withValues(alpha: 0.1)
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
          else if (_recordedFilePath != null)
            Column(
              children: [
                Icon(Icons.check_circle, size: 48, color: widget.accentColor),
                const SizedBox(height: 8),
                Text(
                  'Recorded: ${_formatDuration(_recordingDuration)}',
                  style: TextStyle(color: widget.accentColor),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _recordedFilePath = null;
                      _recordingDuration = Duration.zero;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-record'),
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
              ),
            ),
        ],
      ),
    );
  }
}
