import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
  late CameraController? cameraController;
  late SharedPreferences prefs;
  
  late List<CameraDescription> _cameras;

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
    await _requestPermissions();

    // Initialize SharedPreferences
    prefs = await SharedPreferences.getInstance();

    //Initialize camera
    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    await cameraController!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _captureImage(ConversationController controller) async {
    if (controller.state.conversationState == ConversationState.processing ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile picture = await cameraController!.takePicture();
      controller.setImageBytes(await picture.readAsBytes());
    } catch (e) {
      print("Error taking picture or processing: $e");
    }
  }

  void onToggleListening(ConversationController controller) async {
    print('Before toggle: ${controller.state.conversationState}');
    if (controller.state.conversationState == ConversationState.idle) {
      print('Capturing image');
      await _captureImage(controller);
      await controller.startListening(prefs.getString('inputLanguage') ?? 'en_IN');
    } else {
      print('Stopping speaking');
      await controller.stopSpeaking();
    }
    print('After toggle: ${controller.state.conversationState}');
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConversationController>(context);

    final AppContentState state = controller.state;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return FutureBuilder(
        future: controller.initialize(),
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
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
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
                  child: Text(state.agentResponse, textAlign: TextAlign.center),
                )
              : const CircularProgressIndicator(),
        ),
      );
    });
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
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: cameraController!.value.previewSize!.height,
                    height: cameraController!.value.previewSize!.width,
                    child: CameraPreview(cameraController!),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: InkWell(
                onTap: () => onToggleListening(controller),
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
                              ConversationState.listening => 'Listening...',
                              ConversationState.processing => 'Processing...\nYou said: ${state.userRecognisedWords}',
                              ConversationState.speaking => state.agentResponse,
                              ConversationState.failed => 'Failed to process your request',
                              ConversationState.idle => 'Tap the mic and speak',
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
                          onPressed: null, // The InkWell now handles the tap
                          backgroundColor: state.conversationState == ConversationState.listening
                              ? Colors.white
                              : Colors.yellow,
                          foregroundColor: state.conversationState == ConversationState.listening
                              ? Colors.yellow
                              : Colors.white,
                          tooltip: state.conversationState == ConversationState.listening
                              ? 'Stop listening'
                              : 'Start listening',
                          elevation: 8.0,
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.yellow, width: 2),
                          ),
                          child: Icon(
                            state.conversationState == ConversationState.listening
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
    });
  }
}
