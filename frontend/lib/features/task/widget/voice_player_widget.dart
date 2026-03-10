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
  final VoidCallback? onDelete;

  const VoicePlayerWidget({
    super.key,
    required this.audioPath,
    this.audioUrl,
    this.title = 'Voice Message',
    this.accentColor = const Color(0xFF00BCD4),
    this.autoPlay = false,
    this.onDelete,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late AudioPlayer _player;
  AudioState _audioState = AudioState.loading;
  Duration _duration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool _sourceLoaded = false;

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
          _player.pause();
        } else if (s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering) {
          _audioState = AudioState.loading;
        } else if (s.playing) {
          _audioState = AudioState.playing;
        } else if (_sourceLoaded) {
          _audioState = AudioState.paused;
        }
      });
    });

    // โหลด audio source ครั้งเดียวตอน init
    _loadAudioSource();
  }

  Future<void> _loadAudioSource() async {
    try {
      setState(() => _audioState = AudioState.loading);
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _player.setUrl(widget.audioUrl!);
      } else {
        await _player.setFilePath(widget.audioPath);
      }
      _sourceLoaded = true;
      if (mounted) {
        setState(() => _audioState = AudioState.stopped);
        if (widget.autoPlay) _player.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _audioState = AudioState.error);
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_sourceLoaded || _audioState == AudioState.loading) return;

    if (_audioState == AudioState.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> _seek(Duration position) async {
    await _player.seek(position);
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
              // Play/Pause Button — instant toggle, no reloading
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (!_sourceLoaded || _audioState == AudioState.loading)
                        ? widget.accentColor.withOpacity(0.5)
                        : widget.accentColor,
                  ),
                  child: _audioState == AudioState.loading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _audioState == AudioState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
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
              // Delete Button — ลบเสียงเพื่อบันทึกใหม่
              GestureDetector(
                onTap: () async {
                  await _player.stop();
                  widget.onDelete?.call();
                },
                child: Icon(Icons.close, color: Colors.grey[600], size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
