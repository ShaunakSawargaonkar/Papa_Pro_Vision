import 'package:papa_pro_vision/Txt2Speech/Models/flutter_tts.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/google_tts.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';

abstract class TextToSpeechService {
  /// Speaks [text] on behalf of the interaction identified by [sessionId].
  /// Audio synthesised for a session that is no longer current is discarded,
  /// including intermediate announcements.
  Future<void> speak(String text, {bool isIntermediate = false, int sessionId});
  Future<void> speak2(String text, {bool isIntermediate = false, int sessionId});
  Future<void> stop();

  /// Opens the audio session for [token] and returns it.
  Future<int> startSession(int token);

  /// Signals that no further audio will be produced for [token], which is what
  /// allows a drained queue to be treated as a finished response.
  Future<void> endSession(int token);
}

TextToSpeechService setupTTSService(
  String selectedModel,
  ConversationController controller,
) {
  switch (selectedModel.toLowerCase()) {
    case 'google':
      return GoogleTTSService(controller);
    case 'fluttertts':
      return FlutterTTSService(controller);
    default:
      throw Exception('Unknown TTS model: $selectedModel');
  }
}
