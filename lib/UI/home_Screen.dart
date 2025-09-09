import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'dart:typed_data';
import 'package:papa_pro_vision/agent_service.dart';
import 'package:papa_pro_vision/UI/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

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

      // Initialize camera
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        cameraController = CameraController(
          _cameras![0],
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
      final XFile picture = await cameraController!.takePicture();
      return await picture.readAsBytes();
    } catch (e) {
      print("Error taking picture or processing: $e");
      return null;
    }
  }

  void onToggleListening(ConversationController controller) async {
    print(
      'Before toggle: ${controller.state.conversationState} ${controller.state.interactionMode} ',
    );

    if (controller.state.conversationState == ConversationState.idle) {
      if (controller.state.interactionMode == InteractionMode.normal) {
        //Capture image
        if (!controller.state.isHistoryMode) {
          _captureImage(controller).then((imageBytes) {
            if (imageBytes != null) {
              controller.setImageBytes(imageBytes);
            }
          });
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
          await controller.processInput();
        } else {
          // Wait a bit for the background image capture to complete before processing
          Uint8List? imageBytes = Uint8List(0);
          print('Capturing image ss');
          imageBytes = await _captureImage(controller);
          if (imageBytes != null) {
            print('Setting image bytes ss');
            controller.setImageBytes(imageBytes);
          }

          await controller.processInput(imageBytes: imageBytes);
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

  void onToggleSmartReadingMode(ConversationController controller) async {
    await controller.toggleSmartReadingMode();
  }

  void onToggleAutoReadingMode(ConversationController controller) async {
    await controller.toggleAutoReadingMode();
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
        future: controller.initialize(),
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
      future: controller.initialize(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Papa ProVision'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                // width: cameraController!.value.previewSize!.height,
                height: MediaQuery.of(context).size.height * 0.55,
                child: Row(
                  children: [
                    // LEFT clickable border
                    InkWell(
                      onTap: () => onToggleAutoReadingMode(controller),
                      child: Container(
                        padding: EdgeInsets.only(right: 10),
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: cameraController!.value.previewSize!.width,
                        color: Colors.blue, // full-height clickable blue area
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            "Auto Reader",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),

                    // CENTER Camera feed
                    Expanded(
                      flex: 8, // take maximum space
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
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
                      onTap: () => onToggleSmartReadingMode(controller),
                      child: Container(
                        padding: EdgeInsets.only(left: 10),
                        height: cameraController!.value.previewSize!.width,
                        width: MediaQuery.of(context).size.width * 0.15,
                        color: Colors.blue, // full-height clickable blue area
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            "Smart Reader",
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
                  child: InkWell(
                    onTap: () async => {
                      await controller.unsetHistoryMode(),
                      onToggleListening(controller),
                    },
                    onDoubleTap: () async => {
                      await controller.setHistoryMode(),
                      onToggleListening(controller),
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: state.agentResponse.isNotEmpty
                              ? SingleChildScrollView(
                                  child: Text(
                                    state.agentResponse,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Text(
                                  switch (state.conversationState) {
                                    ConversationState.listening =>
                                      'Listening...',
                                    ConversationState.processing =>
                                      'Processing...\nYou said: ${state.userRecognisedWords}',
                                    ConversationState.speaking =>
                                      state.agentResponse,
                                    ConversationState.failed =>
                                      'Failed to process your request',
                                    ConversationState.idle =>
                                      'Tap the mic and speak',
                                    _ => 'Tap the mic and speak',
                                  },
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        Expanded(
                          child: Transform.scale(
                            scale: 2.0,
                            child: FloatingActionButton(
                              onPressed:
                                  null, // The InkWell now handles the tap
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
                                side: BorderSide(
                                  color: Colors.yellow,
                                  width: 2,
                                ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
