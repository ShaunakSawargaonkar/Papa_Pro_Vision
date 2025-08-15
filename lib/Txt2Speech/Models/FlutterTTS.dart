import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';

class FlutterTTS implements TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
