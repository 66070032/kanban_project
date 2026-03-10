import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Audio Recording Service using the `record` package
class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;

  /// Returns true if microphone permission is granted.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Start recording and return the file path.
  Future<String> startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) throw Exception('Microphone permission denied');

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 256000,
        sampleRate: 44100,
        numChannels: 2,
      ),
      path: path,
    );
    _isRecording = true;
    _recordingPath = path;
    return path;
  }

  /// Stop recording and return the saved file path.
  Future<String> stopRecording() async {
    final path = await _recorder.stop();
    _isRecording = false;
    return path ?? _recordingPath ?? '';
  }

  /// Cancel the current recording without saving.
  Future<void> cancelRecording() async {
    await _recorder.cancel();
    _isRecording = false;
    _recordingPath = null;
  }

  Future<void> dispose() async => _recorder.dispose();
}
