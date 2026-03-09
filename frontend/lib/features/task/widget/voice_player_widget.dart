import 'package:flutter/material.dart';

enum AudioState { loading, playing, paused, stopped, error }

/// Voice Player Widget
/// Reusable widget for playing voice instructions and reminders
class VoicePlayerWidget extends StatefulWidget {
  final String audioPath;
  final String? audioUrl;
  final String title;
  final Color accentColor;
  final bool autoPlay;

  const VoicePlayerWidget({
    super.key,
    required this.audioPath,
    this.audioUrl,
    this.title = 'Voice Message',
    this.accentColor = const Color(0xFF00BCD4),
    this.autoPlay = false,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  AudioState _audioState = AudioState.stopped;
  Duration _duration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      Future.microtask(() => _play());
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      setState(() => _audioState = AudioState.loading);

      // TODO: Implement actual playback with 'just_audio' package
      // final playbackService = AudioPlaybackService();
      // if (widget.audioUrl != null) {
      //   await playbackService.playFromUrl(widget.audioUrl!);
      // } else {
      //   await playbackService.play(widget.audioPath);
      // }

      setState(() {
        _audioState = AudioState.playing;
        _isPlaying = true;
        _duration = const Duration(seconds: 30); // Placeholder
      });

      // Simulate playback completion
      await Future.delayed(_duration);
      if (mounted) {
        _stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _audioState = AudioState.error);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  Future<void> _pause() async {
    try {
      setState(() {
        _audioState = AudioState.paused;
        _isPlaying = false;
      });

      // TODO: Implement actual pause
      // final playbackService = AudioPlaybackService();
      // await playbackService.pause();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pausing: $e')));
      }
    }
  }

  Future<void> _resume() async {
    try {
      setState(() {
        _audioState = AudioState.playing;
        _isPlaying = true;
      });

      // TODO: Implement actual resume
      // final playbackService = AudioPlaybackService();
      // await playbackService.resume();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resuming: $e')));
      }
    }
  }

  Future<void> _stop() async {
    try {
      setState(() {
        _audioState = AudioState.stopped;
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });

      // TODO: Implement actual stop
      // final playbackService = AudioPlaybackService();
      // await playbackService.stop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping: $e')));
      }
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      setState(() => _currentPosition = position);

      // TODO: Implement actual seek
      // final playbackService = AudioPlaybackService();
      // await playbackService.seek(position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error seeking: $e')));
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
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: _audioState == AudioState.loading
                    ? null
                    : (_isPlaying
                          ? _pause
                          : (_audioState == AudioState.paused
                                ? _resume
                                : _play)),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor,
                  ),
                  child: Icon(
                    _audioState == AudioState.loading
                        ? Icons.hourglass_bottom
                        : (_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Progress Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: _currentPosition.inSeconds.toDouble(),
                        max: _duration.inSeconds.toDouble(),
                        onChanged: (value) =>
                            _seek(Duration(seconds: value.toInt())),
                        activeColor: widget.accentColor,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Stop Button
              GestureDetector(
                onTap: _stop,
                child: Icon(Icons.close, color: Colors.grey[600], size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
