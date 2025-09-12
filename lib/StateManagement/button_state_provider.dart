import 'package:flutter/foundation.dart';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceAudioHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:papa_pro_vision/agent_service.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:papa_pro_vision/text_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:papa_pro_vision/secrets.dart';
import 'package:papa_pro_vision/enums.dart';

class AppContentState {
  String agentResponse = '';
  String userRecognisedWords = '';
  ConversationState? conversationState = ConversationState.idle;
  InteractionMode? interactionMode = InteractionMode.normal;
  bool isHistoryMode = false;

  AppContentState();
}

class ConversationController extends ChangeNotifier {
  AppContentState get state => _appContentState;
  AgentService? _agentService;
  TextToSpeechService? _ttsService;
  SpeechToText? _speechToText;
  AppContentState _appContentState = AppContentState();
  Uint8List _imageBytes = Uint8List(0);
  final TextService _textService = TextService();

  Future<void> initialize(String inputLanguage, bool enableTranslation) async {
    _ttsService ??= setupTTSService('google', this);
    if (_agentService == null) {
      _agentService = AgentService(this);
      _agentService?.initialize(
        Secrets.geminiApiKey,
        InteractionMode.normal,
        TextService.inputLanguageToCommunicationLanguage[inputLanguage] ??
            'English',
        enableTranslation,
      );
    }

    if (_speechToText == null) {
      _speechToText = SpeechToText();
      final bool? speechInitialized = await _speechToText?.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done') {
            DeviceAudioHelper.playMicOFFSound();
            if (state.userRecognisedWords.isNotEmpty) {
              print('Processing input');
              print(
                'Image bytes: ${_imageBytes.isNotEmpty} ${state.isHistoryMode}',
              );
              if (state.isHistoryMode) {
                processInput(inputLanguage);
              } else if (_imageBytes.isNotEmpty) {
                processInput(inputLanguage, imageBytes: _imageBytes);
              }
            }
          }
        },
        onError: (error) {
          DeviceAudioHelper.playMicOFFSound();
          _appContentState.conversationState = ConversationState.failed;
          notifyListeners();
          print('Speech error: $error');
        },
      );
      if (speechInitialized == false || speechInitialized == null) {
        _appContentState.conversationState = ConversationState.failed;
        notifyListeners();
      }
    }
  }

  void resetAgentChat() {
    _agentService?.reset();
  }

  Future<void> processInput(
    String inputLanguage, {
    Uint8List? imageBytes,
  }) async {
    var hasInternet = await Devicehelper.hasInternetConnectionAndNotify(
      methodCallName: 'processInput',
    );
    if (!hasInternet) {
      print('No internet connection. Cannot process input.');
      _appContentState.conversationState = ConversationState.idle;
      notifyListeners();
      return;
    }
    String defaultPrompt = _textService.getPromptText(
      inputLanguage,
      state.interactionMode,
    );
    var promptText = state.userRecognisedWords.isNotEmpty
        ? state.userRecognisedWords
        : defaultPrompt;

    if (_appContentState.interactionMode == InteractionMode.smartView) {
      promptText = defaultPrompt;
      _appContentState.userRecognisedWords = 'SMART READING MODE';
    } else if (_appContentState.interactionMode ==
        InteractionMode.autoReading) {
      promptText = defaultPrompt;
      _appContentState.userRecognisedWords = 'AUTO READING MODE';
    }

    //Calling Gemini
    _appContentState.conversationState = ConversationState.processing;
    notifyListeners();
    if (_appContentState.interactionMode == InteractionMode.normal) {
      await _ttsService?.speak(
        _textService.getProcessingResponseText(inputLanguage),
        isIntermediate: true,
      );
    }
    if (!state.isHistoryMode) {
      _agentService?.reset();
    }
    final response = await _agentService?.generateResponse(
      promptText,
      imageBytes: imageBytes,
      inputLanguage,
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
    DeviceAudioHelper.playMicONSound();
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
    if (_appContentState.interactionMode != InteractionMode.normal) {
      SharedPreferences? prefs = await SharedPreferences.getInstance();
      _appContentState.interactionMode = InteractionMode.normal;

      _agentService?.initialize(
        Secrets.geminiApiKey,
        InteractionMode.smartView,
        prefs.getString('inputLanguage') ?? 'en_IN',
        prefs.getBool('enableTranslation') ?? false,
      );
    }
    _appContentState.userRecognisedWords = '';
    await _ttsService?.stop();
    notifyListeners();
  }

  void setImageBytes(Uint8List imageBytes) {
    _imageBytes = imageBytes;
    notifyListeners();
  }

  Uint8List getImageBytes() {
    return _imageBytes;
  }

  Future<void> doneSpeaking() async {
    if (_appContentState.conversationState == ConversationState.speaking) {
      _appContentState.conversationState = ConversationState.idle;
      if (_appContentState.interactionMode != InteractionMode.normal) {
        SharedPreferences? prefs = await SharedPreferences.getInstance();
        _appContentState.interactionMode = InteractionMode.normal;

        _agentService?.initialize(
          Secrets.geminiApiKey,
          InteractionMode.smartView,
          prefs.getString('inputLanguage') ?? 'en_IN',
          prefs.getBool('enableTranslation') ?? false,
        );
      }

      _appContentState.userRecognisedWords = '';
      await _ttsService?.stop();
      notifyListeners();
    }
  }

  Future<void> setHistoryMode() async {
    var isInternetAvailable = await Devicehelper.hasInternetConnectionAndNotify(
      methodCallName: 'setHistoryMode',
    );
    if (!isInternetAvailable) {
      print("No internet connection. Cannot set history mode.");
      return;
    }
    if (_appContentState.conversationState == ConversationState.idle) {
      if (_appContentState.interactionMode == InteractionMode.smartView) {
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
    var isInternetAvailable = await Devicehelper.hasInternetConnectionAndNotify(
      methodCallName: 'unsetHistoryMode',
    );
    if (!isInternetAvailable) {
      print("No internet connection. Cannot perform unsetHistoryMode.");
      return;
    }
    if (_appContentState.conversationState == ConversationState.idle) {
      if (_appContentState.interactionMode == InteractionMode.smartView) {
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

  Future<void> setSmartViewMode(
    String communicationLanguage,
    bool enableTranslation,
  ) async {
    Analyticshelper.updateResponseCount("SmartViewModeCount");
    print('Toggle reading mode: ${_appContentState.interactionMode}');
    _appContentState.interactionMode = InteractionMode.smartView;
    _agentService?.initialize(
      Secrets.geminiApiKey,
      InteractionMode.smartView,
      communicationLanguage,
      enableTranslation,
    );
    await _ttsService?.speak(
      _textService.getSmartViewText(communicationLanguage, true),
      isIntermediate: true,
    );
    notifyListeners();
  }

  Future<void> unSetSmartViewMode(
    String communicationLanguage,
    bool enableTranslation,
  ) async {
    _appContentState.interactionMode = InteractionMode.normal;
    _agentService?.initialize(
      Secrets.geminiApiKey,
      InteractionMode.normal,
      communicationLanguage,
      enableTranslation,
    );
    await _ttsService?.speak(
      _textService.getSmartViewText(communicationLanguage, false),
      isIntermediate: true,
    );
    notifyListeners();
  }

  Future<void> setAutoReadingMode(
    String communicationLanguage,
    bool enableTranslation,
  ) async {
    Analyticshelper.updateResponseCount("ReaderModeCount");
    _appContentState.interactionMode = InteractionMode.autoReading;
    _agentService?.initialize(
      Secrets.geminiApiKey,
      InteractionMode.autoReading,
      communicationLanguage,
      enableTranslation,
    );
    if (enableTranslation) {
      Analyticshelper.updateResponseCount("TranslationCount");
    }
    await _ttsService?.speak(
      _textService.getAutoReaderText(communicationLanguage, true),
      isIntermediate: true,
    );
    notifyListeners();
  }

  Future<void> unSetAutoReadingMode(
    String communicationLanguage,
    bool enableTranslation,
  ) async {
    _appContentState.interactionMode = InteractionMode.normal;
    _agentService?.initialize(
      Secrets.geminiApiKey,
      InteractionMode.normal,
      communicationLanguage,
      enableTranslation,
    );
    notifyListeners();
  }
}
