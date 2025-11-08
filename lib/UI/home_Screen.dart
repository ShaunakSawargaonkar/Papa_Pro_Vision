import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
import 'dart:io';
import 'package:papa_pro_vision/UI/widgets/image_preview.dart';
import 'package:papa_pro_vision/UI/widgets/side_bar_button.dart';

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
      if (controller.state.interactionMode == InteractionMode.normal) {
        await Future.delayed(
          Duration(milliseconds: 500),
        ); // wait for camera sound to complete
      }
      return await picture.readAsBytes();
    } catch (e) {
      print("Error taking picture or processing: $e");
      return null;
    }
  }

  Future<void> _startRecording(ConversationController controller) async {
    if (controller.state.conversationState != ConversationState.idle ||
        !cameraController!.value.isInitialized) {
      return;
    }
    try {
      await controller.startVideoRecording();
      await cameraController!.startVideoRecording();
      print('Started recording video');
    } catch (e) {
      print('Error starting video recording: $e');
      controller.stopVideoRecording();
    }
  }

  Future<void> _stopRecording(ConversationController controller) async {
    if (controller.state.conversationState !=
        ConversationState.videoRecording) {
      return;
    }

    try {
      final XFile videoFile = await cameraController!.stopVideoRecording();

      // Convert XFile to File and call the callback
      final File file = File(videoFile.path);

      await controller.stopVideoRecording(file: file);
      print('Stopped recording video: ${videoFile.path}');
    } catch (e) {
      print('Error stopping video recording: $e');
      controller.stopVideoRecording();
    }
  }

  Future<void> _cancelRecording(ConversationController controller) async {
    if (controller.state.conversationState !=
        ConversationState.videoRecording) {
      return;
    }
    try {
      final XFile videoFile = await cameraController!.stopVideoRecording();
      print('Stopped recording video: ${videoFile.path}');
    } catch (e) {
      print('Error stopping video recording: $e');
      controller.stopVideoRecording();
    }
  }

  Future<void> onToggleListening(ConversationController controller) async {
    print(
      'Before toggle: ${controller.state.conversationState} ${controller.state.interactionMode} ${controller.state.isHistoryMode}',
    );

    // prefs = await SharedPreferences.getInstance();
    // Image mode
    print(prefs?.getString('inputLanguage'));

    if (controller.state.conversationState == ConversationState.idle) {
      if (controller.state.interactionMode == InteractionMode.normal) {
        //Capture image
        Uint8List? imageBytes = Uint8List(0);
        if (!controller.state.isHistoryMode &&
            !controller.state.hasUploadedImage) {
          imageBytes = await _captureImage(controller);
          if (imageBytes != null) {
            controller.setImageBytes(imageBytes);
          }
        } else {
          if (controller.getImageBytes().isNotEmpty) {
            if (controller.state.hasUploadedImage) {
              Analyticshelper.updateResponseCount(
                "LLMInteractionWithUploadedImageCount",
              );
            } else {
              Analyticshelper.updateResponseCount(
                "LLMInteractionWithImageCount",
              );
            }
          } else {
            Analyticshelper.updateResponseCount("JustLLMInteractionCount");
          }
        }
        await controller.startListening(
          prefs?.getString('inputLanguage') ?? 'en_IN',
        );
      }
      // Video mode
      else if (controller.state.interactionMode == InteractionMode.video) {
        Analyticshelper.updateResponseCount("VideoModeCount");
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
      Analyticshelper.updateResponseCount("CancelledRequestCount");
      if (controller.chatHistoryCount() == 0 && controller.state.isHistoryMode) {
        print("Insideee Stopping google search speaking");
        await controller.stopSpeakingForGoogleSearch();
      } else {
        print("Insideee Stopping non google search speaking");
        await controller.stopSpeaking();
      }
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
      controller.unsetUploadedImageMode(
        prefs?.getString('inputLanguage') ?? 'en_IN',
        prefs?.getBool('enableTranslation') ?? false,
      );
    }
  }

  PreferredSizeWidget appBar(
    ConversationController controller,
    double largeFontSize,
  ) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return AppBar(
      title: Row(
        children: [
          Image.asset('assets/logo_color.png', width: 30, height: 30),
          const SizedBox(width: 10),
          Text('Letsee', style: TextStyle(fontSize: deviceWidth * 0.06)),
        ],
      ),
      actions: [
        Semantics(
          label: "Profile Settings button",
          excludeSemantics: true,
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              await _initialize();
              controller.initializeAgent(
                prefs?.getString('inputLanguage') ?? 'en_IN',
                prefs?.getBool('enableTranslation') ?? false,
                InteractionMode.normal,
              );
              // onSettingsChanged?.call();
            },
          ),
        ),
      ],
    );
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
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    final largeFontSize = deviceWidth * 0.065;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return FutureBuilder(
        future: controller.initialize(
          prefs?.getString('inputLanguage') ?? 'en_IN',
          prefs?.getBool('enableTranslation') ?? false,
        ),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: appBar(controller, largeFontSize),
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
          appBar: appBar(controller, largeFontSize),
          body: Column(
            children: [
              SizedBox(
                height: deviceHeight * 0.55,
                child: Stack(
                  children: [
                    // BOTTOM LAYER: Full-width Camera feed
                    Semantics(
                      label: controller.getImageBytes().isNotEmpty
                          ? "Clear image"
                          : "Camera feed",
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => clearImageBuffer(controller),
                        child: ClipRect(
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: ImagePreview(
                              cameraController: cameraController!,
                              hasUploadedImage:
                                  controller.state.hasUploadedImage,
                              imageBytes: controller.getImageBytes(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TOP LAYER: Left and Right sidebars positioned on top
                    Positioned.fill(
                      child: Row(
                        children: [
                          // LEFT clickable border
                          SideBarButton(
                            buttonText: "Reader Mode",
                            onTap: () async {
                              await controller.unsetHistoryMode();
                              await controller.setAutoReadingMode(
                                prefs?.getString('inputLanguage') ?? 'en_IN',
                                prefs?.getBool('enableTranslation') ?? false,
                              );
                              onToggleListening(controller);
                            },
                            height: double.infinity,
                            largeFontSize: largeFontSize,
                            isLeft: true,
                          ),

                          // SPACER - to push right sidebar to the right
                          Spacer(),

                          // RIGHT clickable border
                          SideBarButton(
                            buttonText: "Smart View Mode",
                            onTap: () async {
                              await controller.unsetHistoryMode();
                              controller.setSmartViewMode(
                                prefs?.getString('inputLanguage') ?? 'en_IN',
                                prefs?.getBool('enableTranslation') ?? false,
                              );
                              onToggleListening(controller);
                            },
                            height: double.infinity,
                            largeFontSize: largeFontSize,
                            isLeft: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: state.agentResponse.isNotEmpty
                    ? deviceHeight * 0.00
                    : deviceHeight * 0.03,
              ),
              SizedBox(
                height: state.agentResponse.isNotEmpty
                    ? deviceHeight * 0.22
                    : deviceHeight * 0.27,
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
                      height: deviceHeight * 0.2,
                      width: deviceWidth * 0.015,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    // Right half - entire area clickable
                    Expanded(
                      child: GestureDetector(
                        onTap: () async => {
                          await controller.unsetHistoryMode(),
                          await controller.unsetUploadedImageMode(
                            prefs?.getString('inputLanguage') ?? 'en_IN',
                            prefs?.getBool('enableTranslation') ?? false,
                          ),
                          onToggleListening(controller),
                        },
                        onLongPressStart: (details) async {
                          await controller.unsetHistoryMode();
                          await _startRecording(controller);
                        },
                        onLongPressEnd: (details) async {
                          await _stopRecording(controller);
                          onToggleListening(controller);
                        },
                        onLongPressCancel: () async {
                          await _cancelRecording(controller);
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
                  padding: EdgeInsets.all(deviceWidth * 0.02),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: deviceWidth * 0.02,
                        vertical: deviceHeight * 0.02,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: deviceHeight * 0.04,
              ), // Add some spacing at the bottom
            ],
          ),
        );
      },
    );
  }
}
