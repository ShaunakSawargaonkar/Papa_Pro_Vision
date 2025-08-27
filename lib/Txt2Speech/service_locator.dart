import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/FlutterTTS.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/GoogleTTS.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/EdgeTTS.dart';

abstract class TextToSpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

final GetIt locator = GetIt.instance;

void setupTTSService(String selectedModel) {
  if (locator.isRegistered<TextToSpeechService>()) {
    locator.unregister<TextToSpeechService>();
  }

  switch (selectedModel.toLowerCase()) {
    case 'google':
      locator.registerSingleton<TextToSpeechService>(GoogleTTS());
      break;
    case 'fluttertts':
      locator.registerSingleton<TextToSpeechService>(FlutterTTS());
      break;
    case 'edgetts':
      locator.registerSingleton<TextToSpeechService>(EdgeTTS());
      break;
    default:
      throw Exception('Unknown TTS model: $selectedModel');
  }
}
