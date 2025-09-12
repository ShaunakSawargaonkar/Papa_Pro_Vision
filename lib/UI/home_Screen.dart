import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceAudioHelper.dart';
import 'dart:typed_data';
import 'package:papa_pro_vision/UI/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:papa_pro_vision/enums.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? cameraController;
  SharedPreferences? prefs;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      setState(() => _isInitializing = true);

      await _requestPermissions();

      // Initialize SharedPreferences
      prefs = await SharedPreferences.getInstance();

      final bool useFrontCamera = prefs?.getBool('useFrontCamera') ?? false;

      _cameras = await availableCameras();
      // Find the appropriate camera
      CameraDescription selectedCamera;
      if (useFrontCamera && _cameras!.length > 1) {
        // Look for front camera
        selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () =>
              _cameras![0], // Fallback to first camera if front not found
        );
      } else {
        // Use back camera (usually index 0)
        selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras![0], // Fallback to first camera
        );
      }

      if (_cameras != null && _cameras!.isNotEmpty) {
        cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.veryHigh,
          enableAudio: false,
        );
        await cameraController?.initialize();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<Uint8List?> _captureImage(ConversationController controller) async {
    if (controller.state.conversationState == ConversationState.processing ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return null;
    }
    try {
      DeviceAudioHelper.playCameraClickSound();
      final XFile picture = await cameraController!.takePicture();
      return await picture.readAsBytes();
    } catch (e) {
      print("Error taking picture or processing: $e");
      return null;
    }
  }

  Future<void> onToggleListening(ConversationController controller) async {
    print(
      'Before toggle: ${controller.state.conversationState} ${controller.state.interactionMode} ${controller.state.isHistoryMode}',
    );

    if (controller.state.conversationState == ConversationState.idle) {
      if (controller.state.interactionMode == InteractionMode.normal) {
        //Capture image
        Uint8List? imageBytes = Uint8List(0);
        if (!controller.state.isHistoryMode) {
          imageBytes = await _captureImage(controller);
          if (imageBytes != null) {
            controller.setImageBytes(imageBytes);
          }
        }
        await controller.startListening(
          prefs?.getString('inputLanguage') ?? 'en_IN',
        );
      }
      // Reading modes
      else {
        print('Capturing image in smart');
        // For non-normal interaction modes, process immediately
        if (controller.state.isHistoryMode) {
          await controller.processInput(
            prefs?.getString('inputLanguage') ?? 'en_IN',
          );
        } else {
          // Wait a bit for the background image capture to complete before processing
          Uint8List? imageBytes = Uint8List(0);
          print('Capturing image ss');
          imageBytes = await _captureImage(controller);
          if (imageBytes != null) {
            print('Setting image bytes ss');
            controller.setImageBytes(imageBytes);
          }

          await controller.processInput(
            prefs?.getString('inputLanguage') ?? 'en_IN',
            imageBytes: imageBytes,
          );
        }
      }
    } else {
      print('Stopping speaking');
      await Analyticshelper.updateResponseCount("CancelledRequestCount");
      await controller.stopSpeaking();
    }
    print(
      'After toggle: ${controller.state.conversationState} ${controller.state.interactionMode}',
    );
  }

  void clearImageBuffer(ConversationController controller) async {
    print("Clearing image buffer");
    DeviceAudioHelper.playDeleteSound();
    if (controller.getImageBytes() != Uint8List(0)) {
      print("Cearing image buffer2");
      controller.setImageBytes(Uint8List(0));
      controller.resetAgentChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing or if camera is not ready
    if (_isInitializing ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Show loading indicator if camera is not initialized
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final controller = Provider.of<ConversationController>(context);

    final AppContentState state = controller.state;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return FutureBuilder(
        future: controller.initialize(
          prefs?.getString('inputLanguage') ?? 'en_IN',
          prefs?.getBool('enableTranslation') ?? false,
        ),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Papa Pro Vision'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                    await _initialize();
                    // onSettingsChanged?.call();
                  },
                ),
              ],
            ),
            body: Center(
              child: state.agentResponse.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        state.agentResponse,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          );
        },
      );
    }
    return FutureBuilder(
      future: controller.initialize(
        prefs?.getString('inputLanguage') ?? 'en_IN',
        prefs?.getBool('enableTranslation') ?? false,
      ),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Papa ProVision'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  await _initialize();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(
                // width: cameraController!.value.previewSize!.height,
                height: MediaQuery.of(context).size.height * 0.55,
                child: Row(
                  children: [
                    // LEFT clickable border
                    InkWell(
                      onTap: () async {
                        await controller.unsetHistoryMode();
                        await controller.setAutoReadingMode(
                          prefs?.getString('inputLanguage') ?? 'en_IN',
                          prefs?.getBool('enableTranslation') ?? false,
                        );
                        onToggleListening(controller);
                      },
                      child: Container(
                        padding: EdgeInsets.only(right: 10),
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: cameraController!.value.previewSize!.width,
                        color: Colors.blue, // full-height clickable blue area
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            "Reader Mode",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),

                    // CENTER Camera feed
                    Expanded(
                      flex: 8, // take maximum space
                      child: InkWell(
                        onTap: () => clearImageBuffer(controller),
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: cameraController!.value.previewSize!.height,
                            height: cameraController!.value.previewSize!.width,
                            child: CameraPreview(cameraController!),
                          ),
                        ),
                      ),
                    ),

                    // RIGHT clickable border
                    InkWell(
                      onTap: () async {
                        await controller.unsetHistoryMode();
                        controller.setSmartViewMode(
                          prefs?.getString('inputLanguage') ?? 'en_IN',
                          prefs?.getBool('enableTranslation') ?? false,
                        );
                        onToggleListening(controller);
                      },

                      child: Container(
                        padding: EdgeInsets.only(left: 10),
                        height: cameraController!.value.previewSize!.width,
                        width: MediaQuery.of(context).size.width * 0.15,
                        color: Colors.blue, // full-height clickable blue area
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            "Smart View Mode",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Transform.scale(
                          scale: 2.0,
                          child: FloatingActionButton(
                            onPressed: () async => {
                              await controller.setHistoryMode(),
                              onToggleListening(controller),
                            },
                            backgroundColor:
                                state.conversationState ==
                                    ConversationState.listening
                                ? Colors.white
                                : Colors.green,
                            foregroundColor:
                                state.conversationState ==
                                    ConversationState.listening
                                ? Colors.green
                                : Colors.white,
                            tooltip:
                                state.conversationState ==
                                    ConversationState.listening
                                ? 'Stop listening'
                                : 'Start listening',
                            elevation: 8.0,
                            shape: const CircleBorder(
                              side: BorderSide(color: Colors.green, width: 2),
                            ),
                            child: Icon(
                              state.conversationState ==
                                      ConversationState.listening
                                  ? Icons.mic_off
                                  : Icons.mic,
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                      // Vertical divider between mic buttons
                      Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        width: 5,
                        color: Colors.grey.withOpacity(0.5),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      Expanded(
                        child: Transform.scale(
                          scale: 2.0,
                          child: FloatingActionButton(
                            onPressed: () async => {
                              await controller.unsetHistoryMode(),
                              onToggleListening(controller),
                            }, // The InkWell now handles the tap
                            backgroundColor:
                                state.conversationState ==
                                    ConversationState.listening
                                ? Colors.white
                                : Colors.yellow,
                            foregroundColor:
                                state.conversationState ==
                                    ConversationState.listening
                                ? Colors.yellow
                                : Colors.white,
                            tooltip:
                                state.conversationState ==
                                    ConversationState.listening
                                ? 'Stop listening'
                                : 'Start listening',
                            elevation: 8.0,
                            shape: const CircleBorder(
                              side: BorderSide(color: Colors.yellow, width: 2),
                            ),
                            child: Icon(
                              state.conversationState ==
                                      ConversationState.listening
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
            ],
          ),
        );
      },
    );
  }
}
