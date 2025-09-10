import 'package:flutter_tts/flutter_tts.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:papa_pro_vision/enums.dart';

class FlutterTTSService implements TextToSpeechService {
  late AppContentState _appContentState;

  FlutterTTSService(ConversationController controller){
    controller.addListener(() {
      _appContentState = controller.state;
    });
  }

  final FlutterTts _flutterTts = FlutterTts();

  @override
  Future<void> speak(String text, {bool isIntermediate = false}) async {
    if(_appContentState.conversationState != ConversationState.speaking && !isIntermediate) return;
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
