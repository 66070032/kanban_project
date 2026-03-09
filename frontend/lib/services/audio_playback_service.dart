import 'package:just_audio/just_audio.dart';

enum PlaybackState { idle, playing, paused, stopped }

/// Audio Playback Service using the `just_audio` package.
class AudioPlaybackService {
  static final AudioPlaybackService _instance =
      AudioPlaybackService._internal();
  factory AudioPlaybackService() => _instance;
  AudioPlaybackService._internal();

  final AudioPlayer _player = AudioPlayer();

  PlaybackState _playbackState = PlaybackState.idle;
  String? _currentFilePath;

  PlaybackState get playbackState => _playbackState;
  String? get currentFilePath => _currentFilePath;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(String filePath) async {
    _currentFilePath = filePath;
    await _player.setFilePath(filePath);
    await _player.play();
    _playbackState = PlaybackState.playing;
  }

  Future<void> playFromUrl(String url) async {
    _currentFilePath = url;
    await _player.setUrl(url);
    await _player.play();
    _playbackState = PlaybackState.playing;
  }

  Future<void> pause() async {
    await _player.pause();
    _playbackState = PlaybackState.paused;
  }

  Future<void> resume() async {
    await _player.play();
    _playbackState = PlaybackState.playing;
  }

  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    _playbackState = PlaybackState.stopped;
  }

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> dispose() async => _player.dispose();
}
