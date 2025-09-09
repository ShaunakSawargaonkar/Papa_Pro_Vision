import 'package:flutter/foundation.dart';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/agent_service.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:papa_pro_vision/secrets.dart';

class AppContentState {
  String agentResponse = '';
  String userRecognisedWords = '';
  ConversationState? conversationState = ConversationState.idle;
  InteractionMode? interactionMode = InteractionMode.normal;
  bool isHistoryMode = false;

  AppContentState();
}

enum ConversationState {
  idle, // waiting for user
  listening, // recording user input
  processing, // playing TTS audio and processing via gemini
  speaking, // playing TTS audio
  failed, // error occurred while setting up speech understanding
}

class ConversationController extends ChangeNotifier {
  AppContentState get state => _appContentState;
  AgentService? _agentService;
  TextToSpeechService? _ttsService;
  SpeechToText? _speechToText;
  AppContentState _appContentState = AppContentState();
  Uint8List _imageBytes = Uint8List(0);

  Future<void> initialize() async {
    _ttsService ??= setupTTSService('google', this);
    if (_agentService == null) {
      _agentService = AgentService(this);
      _agentService?.initialize(Secrets.geminiApiKey, InteractionMode.normal);
    }

    if (_speechToText == null) {
      _speechToText = SpeechToText();
      final bool? speechInitialized = await _speechToText?.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done') {
            if (state.userRecognisedWords.isNotEmpty) {
              print('Processing input');
              print(
                'Image bytes: ${_imageBytes.isNotEmpty} ${state.isHistoryMode}',
              );
              if (state.isHistoryMode) {
                processInput();
              } else if (_imageBytes.isNotEmpty) {
                processInput(imageBytes: _imageBytes);
              }
            }
          }
        },
        onError: (error) {
          print('Speech error: $error');
        },
      );
      if (speechInitialized == false || speechInitialized == null) {
        _appContentState.conversationState = ConversationState.failed;
        notifyListeners();
      }
    }
  }

  Future<void> processInput({Uint8List? imageBytes}) async {
    var promptText = state.userRecognisedWords.isNotEmpty
        ? state.userRecognisedWords
        : "What do you see in the image? Describe it for a blind person.";

    if (_appContentState.interactionMode == InteractionMode.smartReading) {
      promptText =
          "Read the text in the image. If the text appears cut off, let me know how to adjust the camera for a better view";
      _appContentState.userRecognisedWords = 'SMART READING MODE`';
    } else if (_appContentState.interactionMode ==
        InteractionMode.autoReading) {
      promptText = "Read the text in the image.";
      _appContentState.userRecognisedWords = 'AUTO READING MODE';
    }

    //Calling Gemini
    _appContentState.conversationState = ConversationState.processing;
    notifyListeners();
    await _ttsService?.speak("Processing response", isIntermediate: true);
    if (!state.isHistoryMode) {
      _agentService?.reset();
    }
    final response = await _agentService?.generateResponse(
      promptText,
      imageBytes: imageBytes,
    );

    if (response != null &&
        response.isNotEmpty &&
        _appContentState.conversationState == ConversationState.processing) {
      _appContentState.agentResponse = response;
      _appContentState.conversationState = ConversationState.speaking;
      notifyListeners();
      await _ttsService?.speak(response);
      // _appContentState.conversationState = ConversationState.idle;
      // notifyListeners();
    }
  }

  Future<void> startListening(String inputLanguage) async {
    _appContentState.conversationState = ConversationState.listening;
    _appContentState.agentResponse = '';
    _appContentState.userRecognisedWords = '';
    notifyListeners();
    await _speechToText?.listen(
      localeId: inputLanguage,
      onResult: (result) {
        _appContentState.userRecognisedWords = result.recognizedWords;
        _appContentState.conversationState = ConversationState.processing;
      },
    );
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    _appContentState.conversationState = ConversationState.idle;
    _appContentState.agentResponse = '';
    _appContentState.userRecognisedWords = '';
    await _ttsService?.stop();
    notifyListeners();
  }

  void setImageBytes(Uint8List imageBytes) {
    _imageBytes = imageBytes;
  }

  Future<void> doneSpeaking() async {
    if (_appContentState.conversationState == ConversationState.speaking) {
      _appContentState.conversationState = ConversationState.idle;
      _appContentState.agentResponse = '';
      _appContentState.userRecognisedWords = '';
      await _ttsService?.stop();
      notifyListeners();
    }
  }

  Future<void> setHistoryMode() async {
    if (_appContentState.conversationState == ConversationState.idle) {
      if (_appContentState.interactionMode == InteractionMode.smartReading) {
        await Analyticshelper.updateResponseCount("SmartReadDoubleTap");
      } else if (_appContentState.interactionMode ==
          InteractionMode.autoReading) {
        await Analyticshelper.updateResponseCount("AutoReadDoubleTap");
      } else {
        await Analyticshelper.updateResponseCount("DoubleTap");
      }
    }
    _appContentState.isHistoryMode = true;
    notifyListeners();
  }

  Future<void> unsetHistoryMode() async {
    if (_appContentState.conversationState == ConversationState.idle) {
      if (_appContentState.interactionMode == InteractionMode.smartReading) {
        await Analyticshelper.updateResponseCount("SmartReadSingleTap");
      } else if (_appContentState.interactionMode ==
          InteractionMode.autoReading) {
        await Analyticshelper.updateResponseCount("AutoReadSingleTap");
      } else {
        await Analyticshelper.updateResponseCount("SingleTap");
      }
    }
    _appContentState.isHistoryMode = false;
    notifyListeners();
  }

  Future<void> toggleSmartReadingMode() async {
    print('Toggle reading mode: ${_appContentState.interactionMode}');
    if (_appContentState.interactionMode != InteractionMode.smartReading) {
      _appContentState.interactionMode = InteractionMode.smartReading;
      _agentService?.initialize(
        Secrets.geminiApiKey,
        InteractionMode.smartReading,
      );
      await _ttsService?.speak("Smart Reader enabled", isIntermediate: true);
      notifyListeners();
    } else {
      _appContentState.interactionMode = InteractionMode.normal;
      _agentService?.initialize(Secrets.geminiApiKey, InteractionMode.normal);
      await _ttsService?.speak("Smart Reader disabled", isIntermediate: true);
      notifyListeners();
    }
  }

  Future<void> toggleAutoReadingMode() async {
    print('Toggle reading mode: ${_appContentState.interactionMode}');
    if (_appContentState.interactionMode != InteractionMode.autoReading) {
      _appContentState.interactionMode = InteractionMode.autoReading;
      _agentService?.initialize(
        Secrets.geminiApiKey,
        InteractionMode.autoReading,
      );
      await _ttsService?.speak("Auto Reader enabled", isIntermediate: true);
      notifyListeners();
    } else {
      _appContentState.interactionMode = InteractionMode.normal;
      _agentService?.initialize(Secrets.geminiApiKey, InteractionMode.normal);
      await _ttsService?.speak("Auto Reader disabled", isIntermediate: true);
      notifyListeners();
    }
  }
}
