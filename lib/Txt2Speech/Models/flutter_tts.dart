import 'package:flutter_tts/flutter_tts.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:papa_pro_vision/enums.dart';

class FlutterTTSService implements TextToSpeechService {
  late AppContentState _appContentState;

  FlutterTTSService(ConversationController controller) {
    _appContentState = controller.state;
    controller.addListener(() {
      _appContentState = controller.state;
    });
  }

  final FlutterTts _flutterTts = FlutterTts();

  @override
  Future<void> speak(
    String text, {
    bool isIntermediate = false,
    int sessionId = -1,
  }) async {
    if (_appContentState.conversationState != ConversationState.speaking &&
        !isIntermediate)
      return;
    await _flutterTts.speak(text);
  }

  @override
  Future<void> speak2(
    String text, {
    bool isIntermediate = false,
    int sessionId = -1,
  }) async {
    if (_appContentState.conversationState != ConversationState.speaking &&
        !isIntermediate)
      return;
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // flutter_tts speaks synchronously through the platform engine and keeps no
  // queue of its own, so there is no session state to open or close here.
  @override
  Future<int> startSession(int token) async => token;

  @override
  Future<void> endSession(int token) async {}
}
