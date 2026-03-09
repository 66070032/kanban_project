import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

enum AudioState { loading, playing, paused, stopped, error }

/// Voice Player Widget  uses `just_audio` for real audio playback.
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
  late AudioPlayer _player;
  AudioState _audioState = AudioState.stopped;
  Duration _duration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _positionSub = _player.positionStream.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });

    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        if (s.processingState == ProcessingState.completed) {
          _audioState = AudioState.stopped;
          _currentPosition = Duration.zero;
          _player.seek(Duration.zero);
        } else if (s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering) {
          _audioState = AudioState.loading;
        } else if (s.playing) {
          _audioState = AudioState.playing;
        } else {
          _audioState = AudioState.paused;
        }
      });
    });

    if (widget.autoPlay) Future.microtask(() => _play());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      setState(() => _audioState = AudioState.loading);
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _player.setUrl(widget.audioUrl!);
      } else {
        await _player.setFilePath(widget.audioPath);
      }
      await _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => _audioState = AudioState.error);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  Future<void> _pause() async => _player.pause();
  Future<void> _resume() async => _player.play();

  Future<void> _stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  Future<void> _seek(Duration position) async => _player.seek(position);

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
                    : (_audioState == AudioState.playing
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
                        : (_audioState == AudioState.playing
                            ? Icons.pause
                            : Icons.play_arrow),
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
                        value: _currentPosition.inMilliseconds
                            .toDouble()
                            .clamp(0, _duration.inMilliseconds.toDouble()),
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1,
                        onChanged: (value) =>
                            _seek(Duration(milliseconds: value.toInt())),
                        activeColor: widget.accentColor,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
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
