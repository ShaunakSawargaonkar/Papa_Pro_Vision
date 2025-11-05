import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceAudioHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:papa_pro_vision/Helper/FileSharingHelper.dart';
import 'package:papa_pro_vision/LLMResponse/agent_service.dart';
import 'package:papa_pro_vision/UI/Txt2Speech/service_locator.dart';
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
  bool hasUploadedImage = false;

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
  FileSharingHelper? _fileSharingHelper;
  File videoFile = File('');

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

    if (_fileSharingHelper == null) {
      _fileSharingHelper = FileSharingHelper();
      _fileSharingHelper?.initialize(this);
    }

    if (_speechToText == null) {
      _speechToText = SpeechToText();
      final bool? speechInitialized = await _speechToText?.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done') {
            DeviceAudioHelper.playMicOFFSound();
            if (state.userRecognisedWords.isNotEmpty) {
              print(
                'Inside speech done: ${_imageBytes.isNotEmpty} ${state.isHistoryMode} ${videoFile.path.isNotEmpty}',
              );
              if (state.isHistoryMode && !state.hasUploadedImage) {
                print("Inside History file processing");
                processInput(inputLanguage, historyMode: true);
              } else if (_imageBytes.isNotEmpty) {
                print("Inside image file processing");
                processInput(inputLanguage, imageBytes: _imageBytes);
              } else if (videoFile.path.isNotEmpty) {
                print("Inside video file processing");
                processInput(inputLanguage, videoFile: videoFile);
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

  int chatHistoryCount() {
    return _agentService!.chatHistoryCount();
  }

  Future<void> processInput(
    String inputLanguage, {
    bool historyMode = false,
    Uint8List? imageBytes,
    File? videoFile,
  }) async {
    SharedPreferences? prefs;
    Content content;
    var hasInternet = await Devicehelper.hasInternetConnectionAndNotify(
      methodCallName: 'processInput',
    );
    if (!hasInternet) {
      print('No internet connection. Cannot process input.');
      _appContentState.conversationState = ConversationState.idle;
      notifyListeners();
      return;
    }
    prefs = await SharedPreferences.getInstance();
    inputLanguage = prefs.getString('inputLanguage') ?? 'en_IN';
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
    if (_appContentState.interactionMode == InteractionMode.normal ||
        _appContentState.interactionMode == InteractionMode.video) {
      await _ttsService?.speak(
        _textService.getProcessingResponseText(inputLanguage),
        isIntermediate: true,
      );
    }
    if (!state.isHistoryMode) {
      _agentService?.reset();
    }
    if ((!state.isHistoryMode || state.hasUploadedImage) && imageBytes != null) {
      print("Inside image generate Response call");
      content =
          await _agentService?.CreateContentForResponse(
                promptText,
                imageBytes: imageBytes,
                inputLanguage,
              )
              as Content;
    } else if (!state.isHistoryMode && videoFile != null) {
      print("Inside video generate Response call");
      content =
          await _agentService?.CreateContentForResponse(
                promptText,
                videoFile: videoFile,
                inputLanguage,
              )
              as Content;
    } else {
      print("Inside history generate Response call");
      content =
          await _agentService?.CreateContentForResponse(
                promptText,
                inputLanguage,
              )
              as Content;
    }

    // Check Gemini or GoogleRenderer
    int chatHistoryCount = _agentService!.chatHistoryCount();
    bool ifGoogle = false;

    if (state.isHistoryMode && chatHistoryCount == 0) {
      ifGoogle = true;
    }

    if (ifGoogle == true) {
      print("Insideeee google search Response call");
      var response = await _agentService?.sendGoogleSearchMessage(
        promptText,
        inputLanguage,
      );
      if (response != null &&
          _appContentState.conversationState == ConversationState.processing) {
        _appContentState.agentResponse = response;
        _appContentState.conversationState = ConversationState.speaking;
        notifyListeners();
        await _ttsService?.speak2(response);
        resetAgentChat();
      }
    } else {
      print("Insideeee streaming Response call");
      await _agentService?.sendStreamingMessage(
        content,
        _ttsService,
        onStartSpeaking,
      );
    }
    // response = await _agentService?.generateResponse(content, inputLanguage);

    // print("Received chunked FINALLLLL: $response");

    // if (response != null &&
    //     response.isNotEmpty &&
    //     _appContentState.conversationState == ConversationState.processing) {
    //   _appContentState.agentResponse = response;
    //   _appContentState.conversationState = ConversationState.speaking;
    //   notifyListeners();
    //   await _ttsService?.speak(response);
    //   // _appContentState.conversationState = ConversationState.idle;
    //   // notifyListeners();
    // }
  }

  Future<void> onStartSpeaking() async {
    if (_appContentState.conversationState == ConversationState.processing) {
      _appContentState.conversationState = ConversationState.speaking;
      notifyListeners();
    }
  }

  void initializeAgent(
    String inputLanguage,
    bool enableTranslation,
    InteractionMode interactionMode,
  ) {
    print(
      'Initializing agent for ${interactionMode} ${inputLanguage} ${enableTranslation}',
    );
    _agentService?.initialize(
      Secrets.geminiApiKey,
      interactionMode,
      inputLanguage,
      enableTranslation,
    );
  }

  Future<void> startVideoRecording() async {
    _appContentState.conversationState = ConversationState.videoRecording;
    _appContentState.agentResponse = '';
    _appContentState.userRecognisedWords = '';
    _imageBytes = Uint8List(0);
    notifyListeners();
    DeviceAudioHelper.playDeleteSound();
  }

  Future<void> stopVideoRecording({File? file}) async {
    print(" Video recording stopped : ${file?.path}");
    if (file != null) videoFile = file;
    _appContentState.conversationState = ConversationState.idle;
    _appContentState.interactionMode = InteractionMode.video;
    _appContentState.agentResponse = '';
    _appContentState.userRecognisedWords = '';
    _imageBytes = Uint8List(0);
    notifyListeners();
    DeviceAudioHelper.playDeleteSound();
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
    SharedPreferences? prefs = await SharedPreferences.getInstance();
    if (_appContentState.interactionMode != InteractionMode.normal) {
      _appContentState.interactionMode = InteractionMode.normal;
    }
    _appContentState.userRecognisedWords = '';
    _agentService?.stopStream(
      Secrets.geminiApiKey,
      InteractionMode.normal,
      TextService.inputLanguageToCommunicationLanguage[prefs.getString(
                'inputLanguage',
              ) ??
              'en_IN'] ??
          'English',
      prefs.getBool('enableTranslation') ?? false,
    );
    await _ttsService?.stop();
    notifyListeners();
  }

  Future<void> stopSpeakingForGoogleSearch() async {
    _appContentState.conversationState = ConversationState.idle;
    if (_appContentState.interactionMode != InteractionMode.normal) {
      _appContentState.interactionMode = InteractionMode.normal;
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

        initializeAgent(
          prefs.getString('inputLanguage') ?? 'en_IN',
          prefs.getBool('enableTranslation') ?? false,
          InteractionMode.normal,
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
    initializeAgent(
      communicationLanguage,
      enableTranslation,
      InteractionMode.smartView,
    );
    _ttsService?.speak(
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
    initializeAgent(
      communicationLanguage,
      enableTranslation,
      InteractionMode.normal,
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
    initializeAgent(
      communicationLanguage,
      enableTranslation,
      InteractionMode.autoReading,
    );
    if (enableTranslation) {
      Analyticshelper.updateResponseCount("TranslationCount");
    }
    _ttsService?.speak(
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
    initializeAgent(
      communicationLanguage,
      enableTranslation,
      InteractionMode.normal,
    );
    notifyListeners();
  }

  Future<void> setUploadedImageMode(Uint8List imageBytes, String communicationLanguage, bool enableTranslation,) async {
    _appContentState.hasUploadedImage = true;
    setImageBytes(imageBytes);
    notifyListeners();
  }

  Future<void> unsetUploadedImageMode(String communicationLanguage, bool enableTranslation) async {
    if (_appContentState.hasUploadedImage) {
      _appContentState.interactionMode = InteractionMode.normal;
      _appContentState.hasUploadedImage = false;
      initializeAgent(
        communicationLanguage,
        enableTranslation,
        InteractionMode.normal,
      );
      notifyListeners();
    }
  }
}
