import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

// IMPORTANT: Replace with your Gemini API Key
const String apiKey = '{APIKEY}';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Assistant',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        primarySwatch: Colors.blue,
      ),
      home: const LiveFeedScreen(),
    );
  }
}

class LiveFeedScreen extends StatefulWidget {
  const LiveFeedScreen({super.key});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late GenerativeModel _generativeModel;
  late FlutterTts _flutterTts;
  final SpeechToText _speechToText = SpeechToText();

  String _responseText = '';
  String _recognizedWords = '';
  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (apiKey == 'YOUR_API_KEY') {
      setState(() {
        _responseText =
            'Please replace "YOUR_API_KEY" with your Gemini API key.';
      });
      return;
    }
    await _requestPermissions();
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    _flutterTts = FlutterTts();
    _generativeModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    _initSpeech();
    if (mounted) {
      setState(() {});
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        // When listening is done, and we have recognized words, trigger processing.
        if (!_isDisposed && (status == 'done' || status == 'notListening')) {
          if (_recognizedWords.isNotEmpty) {
            _captureAndProcessImage();
          }
          setState(() {}); // Update button state
        }
      },
      onError: (error) {
        print('Speech error: $error');
        if (!_isDisposed) setState(() {}); // Update button state
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

  void _toggleListening() {
    print("inside _toggleListening");
    if (!_speechEnabled || _isProcessing) return;

    if (_speechToText.isListening) {
      _speechToText.stop();
    } else {
      _flutterTts.stop(); // Stop any ongoing speech
      if (_cameraController == null || !_cameraController!.value.isInitialized)
        return;
      setState(() {
        _recognizedWords = '';
        _responseText = '';
      });
      _speechToText.listen(
        onResult: (result) {
          if (!_isDisposed) {
            setState(() {
              _recognizedWords = result.recognizedWords;
            });
          }
        },
      );
    }
    setState(() {}); // Update UI to reflect listening state
  }

  Future<void> _captureAndProcessImage() async {
    print("inside _captureAndProcessImage");
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
      final Uint8List imageBytes = await picture.readAsBytes();
      await _processImage(imageBytes);
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
    print("inside _processImage");
    try {
      final promptText = _recognizedWords.isNotEmpty
          ? _recognizedWords
          : "What do you see in the image? Describe it for a blind person.";
      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', imageBytes);
      print("promptText: $promptText");

      final response = await _generativeModel.generateContent([
        Content.multi([prompt, imagePart]),
      ]);
      print('_responseTexteeeeee: ${response.text}');
      if (response.text != null && !_isDisposed) {
        setState(() {
          _responseText = response.text!;
          // Do not clear recognized words here, keep them for context
        });
        print('_responseTexteeeeee: $_responseText');
        await _speak(_responseText);
      }
    } on GenerativeAIException catch (e) {
      print('GenerativeAIException: ${e.message}');
      if (!_isDisposed) {
        setState(() {
          _responseText = 'Error from AI Service: ${e.message}';
        });
      }
    } catch (e) {
      print('Error processing image: $e');
      if (!_isDisposed) {
        setState(() {
          _responseText = 'An unexpected error occurred: $e';
        });
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Papa ProVision')),
        body: Center(
          child: _responseText.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_responseText, textAlign: TextAlign.center),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Papa ProVision')),
      body: Column(
        children: [
          Expanded(
            flex: 5, // Give the camera a bit less space
            child: ClipRect(
              // This ensures that the preview doesn't overflow its container.
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    // Use the camera's aspect ratio to size the preview.
                    width: _cameraController!.value.previewSize!.height,
                    height: _cameraController!.value.previewSize!.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3, // Give more space to controls and text
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _responseText.isNotEmpty
                          ? SingleChildScrollView(
                              child: Text(
                                _responseText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              _isProcessing
                                  ? 'Processing...'
                                  : _speechToText.isListening
                                  ? 'Listening...'
                                  : _recognizedWords.isNotEmpty
                                  ? 'You said: $_recognizedWords'
                                  : 'Tap the mic and speak',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ), // Empty container when no text
                    ),
                    // const SizedBox(width: 1),
                    Expanded(
                      child: Transform.scale(
                        scale: 2.0,
                        child: FloatingActionButton(
                          onPressed: _toggleListening,
                          backgroundColor: _speechToText.isListening
                              ? Colors.white
                              : Colors.yellow,
                          foregroundColor: _speechToText.isListening
                              ? Colors.yellow
                              : Colors.white,
                          tooltip: _speechToText.isListening
                              ? 'Stop listening'
                              : 'Start listening',
                          elevation: 8.0,
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.yellow, width: 2),
                          ),
                          child: Icon(
                            _speechToText.isListening
                                ? Icons.mic_off
                                : Icons.mic,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
