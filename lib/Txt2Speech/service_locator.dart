import 'package:get_it/get_it.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/flutter_tts.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/google_tts.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';

abstract class TextToSpeechService {
  Future<void> speak(String text, {bool isIntermediate = false});
  Future<void> stop();
}

final GetIt locator = GetIt.instance;

TextToSpeechService setupTTSService(String selectedModel, ConversationController controller) {
  // if (locator.isRegistered<TextToSpeechService>()) {
  //   locator.unregister<TextToSpeechService>();
  // }

  switch (selectedModel.toLowerCase()) {
    case 'google':
      return GoogleTTSService(controller);
    case 'fluttertts':
      return FlutterTTSService(controller);
    default:
      throw Exception('Unknown TTS model: $selectedModel');
  }
}
