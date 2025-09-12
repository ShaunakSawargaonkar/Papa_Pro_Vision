import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceAudioHelper.dart';
import 'package:papa_pro_vision/UI/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:papa_pro_vision/enums.dart';
import 'package:papa_pro_vision/UI/widgets/mic_button.dart';

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
      Analyticshelper.updateResponseCount("ImageCaptureCount");
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
        } else {
          if (controller.getImageBytes().isNotEmpty) {
            await Analyticshelper.updateResponseCount(
              "LLMInteractionWithImageCount",
            );
          } else {
            await Analyticshelper.updateResponseCount(
              "JustLLMInteractionCount",
            );
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
    if (controller.getImageBytes().isNotEmpty ||
        controller.getImageBytes() != Uint8List(0)) {
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
                Semantics(
                  label: "Profile Settings button",
                  excludeSemantics: true,
                  child: IconButton(
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
              Semantics(
                label: "Profile Settings button",
                excludeSemantics: true,
                child: IconButton(
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
                      child: Semantics(
                        label: controller.getImageBytes().isNotEmpty
                            ? "Clear image"
                            : "Camera feed",
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => clearImageBuffer(controller),
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width:
                                  cameraController!.value.previewSize!.height,
                              height:
                                  cameraController!.value.previewSize!.width,
                              child: CameraPreview(cameraController!),
                            ),
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
                child: Row(
                  children: [
                    // Left half - entire area clickable
                    Expanded(
                      child: InkWell(
                        onTap: () async => {
                          await controller.setHistoryMode(),
                          onToggleListening(controller),
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: MicButton(
                              conversationState:
                                  state.conversationState ??
                                  ConversationState.idle,
                              baseColor: Colors.green,
                              baseMode: "Ask any question with chat history",
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Vertical divider between mic buttons
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: 2,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    // Right half - entire area clickable
                    Expanded(
                      child: InkWell(
                        onTap: () async => {
                          await controller.unsetHistoryMode(),
                          onToggleListening(controller),
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: MicButton(
                              conversationState:
                                  state.conversationState ??
                                  ConversationState.idle,
                              baseColor: Colors.yellow,
                              baseMode: "Ask question on an image",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.agentResponse.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: state.agentResponse),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Response copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Response'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
