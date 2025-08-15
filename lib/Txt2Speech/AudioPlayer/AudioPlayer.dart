import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAudio(Uint8List bytes) async {
    try {
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      print("Error playing audio from bytes: $e");
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
