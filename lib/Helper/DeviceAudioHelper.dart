import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class _AudioManager {
  static final _AudioManager _instance = _AudioManager._internal();
  factory _AudioManager() => _instance;
  _AudioManager._internal() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentSoundType = null;
      print('Audio completed: $_currentSoundType');
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentSoundType;

  Future<void> playSound(String soundType, List<String> soundPaths) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      print('Stopped $_currentSoundType to play $soundType');
    }

    _isPlaying = true;
    _currentSoundType = soundType;

    try {
      for (String soundPath in soundPaths) {
        try {
          if (soundPath.startsWith('/system/')) {
            await _audioPlayer.play(DeviceFileSource(soundPath));
          } else {
            await _audioPlayer.play(AssetSource(soundPath));
          }
          print('Successfully playing: $soundPath');
          break;
        } catch (e) {
          print('Failed to play $soundPath: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error playing $soundType sound: $e');
      _isPlaying = false;
      _currentSoundType = null;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

class DeviceAudioHelper {
  static final _AudioManager _audioManager = _AudioManager();

  static Future<void> playCameraClickSound() async {
    await _audioManager.playSound('camera', ['sounds/camera-13695.mp3']);
  }

  static Future<void> playInternetNotAvailableSound() async {
    print("Playing Internet Not Available Sound2");
    final FlutterTts _flutterTts = FlutterTts();
    _flutterTts.speak(
      'Internet not available. Please check your connection and try again.',
    );
  }

  static Future<void> playMicONSound() async {
    await _audioManager.playSound('micOn', [
      '/system/media/audio/ui/VideoRecord.ogg',
      '/system/media/audio/ui/Effect_Tick.ogg',
      '/system/media/audio/ui/KeypressStandard.ogg',
    ]);
  }

  static Future<void> playMicOFFSound() async {
    await _audioManager.playSound('micOff', [
      '/system/media/audio/ui/VideoStop.ogg',
      '/system/media/audio/ui/Effect_Tick.ogg',
      '/system/media/audio/ui/KeypressStandard.ogg',
    ]);
  }

  static void dispose() {
    _audioManager.dispose();
  }
}
