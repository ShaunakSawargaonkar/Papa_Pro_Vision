import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';

class FlutterTTS implements TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  @override
  Future<void> speak(String text) async {
    _isPlaying = true;
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }
}
