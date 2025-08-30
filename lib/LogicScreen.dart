import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/FlutterTTS.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:papa_pro_vision/agent_service.dart';

const String apiKey = '{Gemeni_API_Key}';

class LogicScreen extends StatefulWidget {
  const LogicScreen({super.key});

  @override
  State<LogicScreen> createState() => _LogicScreenState();
}

class _LogicScreenState extends State<LogicScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late AgentService _agentService;
  late TextToSpeechService _ttsService;
  final SpeechToText _speechToText = SpeechToText();

  String _responseText = '';
  String _recognizedWords = '';
  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _speechEnabled = false;
  Uint8List _imageBytes = Uint8List(0);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    //print(dotenv.env['GEMINIAPIKEY']);
    if (apiKey == 'YOUR_API_KEY') {
      setState(() {
        _responseText =
            'Please replace "YOUR_API_KEY" with your Gemini API key.';
      });
      return;
    }
    //Permission request and camera initialization
    await _requestPermissions();

    //Initialize camera
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    await _cameraController!.initialize();

    //initialize Text to speech
    setupTTSService('google');
    _ttsService = locator<TextToSpeechService>();
    // Example: using Google TTS
    // _ttsService = TextToSpeechService();

    //Initialize Generative AI model
    _agentService = AgentService();
    _agentService.initialize(apiKey, Mode.normal);
    _initSpeech();
    if (mounted) {
      setState(() {});
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (!_isDisposed && (status == 'done')) {
          if (_recognizedWords.isNotEmpty && _imageBytes.isNotEmpty) {
            _processImage(_imageBytes);
          }
          setState(() {});
        }
      },
      onError: (error) {
        print('Speech error: $error');
        if (!_isDisposed) setState(() {});
      },
    );
    if (!_isDisposed) setState(() {});
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_speechEnabled) return;  // speech to text not initialized
    _isProcessing = false;
    if (_speechToText.isListening) {
      _speechToText.stop();
    } else {
       if (_cameraController == null || !_cameraController!.value.isInitialized){
        return;
       }
      if (_ttsService.isPlaying) {
        _ttsService.stop();
      }else{
        setState(() {
          _recognizedWords = '';
          _responseText = '';
        });
        final prefs = await SharedPreferences.getInstance();
        await _captureImage();
        _speechToText.listen(
          localeId: prefs.getString('inputLanguage') ?? 'en_IN',
          onResult: (result) {
            if (!_isDisposed) {
              setState(() {
                _recognizedWords = result.recognizedWords;
              });
            }
          },
        );
      }
    }
    setState(() {});
  }

  Future<void> _captureImage() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile picture = await _cameraController!.takePicture();
      _imageBytes = await picture.readAsBytes();
    } catch (e) {
      print("Error taking picture or processing: $e");
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImage(Uint8List imageBytes) async {
    final promptText = _recognizedWords.isNotEmpty
        ? _recognizedWords
        : "What do you see in the image? Describe it for a blind person.";

    //Calling Gemini
    await _ttsService.speak("Processing response");
    final response = await _agentService.generateResponse(promptText, imageBytes);

    if (response.isNotEmpty && !_isDisposed) {
      setState(() {
        _responseText = response;
      });
      await _ttsService.speak(_responseText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      cameraController: _cameraController,
      responseText: _responseText,
      recognizedWords: _recognizedWords,
      isProcessing: _isProcessing,
      isListening: _speechToText.isListening,
      onToggleListening: _toggleListening,
      //TODO make this work
      // onSettingsChanged: () async {
      //   // Reload language preference when returning from settings
      //   await _loadSelectedLanguage();
      // },
    );
  }
}
