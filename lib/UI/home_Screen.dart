import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:papa_pro_vision/UI/profile_page.dart';

class HomeScreen extends StatelessWidget {
  final CameraController? cameraController;
  final String responseText;
  final String recognizedWords;
  final bool isProcessing;
  final bool isListening;
  final VoidCallback nonHistoryMode;
  final VoidCallback readingMode;
  final VoidCallback historyToggleListen;
  final VoidCallback? onSettingsChanged;

  const HomeScreen({
    super.key,
    required this.cameraController,
    required this.responseText,
    required this.recognizedWords,
    required this.isProcessing,
    required this.isListening,
    required this.readingMode,
    required this.historyToggleListen,
    required this.nonHistoryMode,
    this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
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
                onSettingsChanged?.call();
              },
            ),
          ],
        ),
        body: Center(
          child: responseText.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(responseText, textAlign: TextAlign.center),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
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
          Container(
                // width: cameraController!.value.previewSize!.height,
                height: MediaQuery.of(context).size.height * 0.55,
            child: Row(
              children: [
                // LEFT clickable border
                InkWell(
                    onTap:readingMode,                        
                    child: Container(
                    child: RotatedBox(quarterTurns: 1,child: Text("Reading Mode",textAlign: TextAlign.center, style: TextStyle(fontSize: 40),)),
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: cameraController!.value.previewSize!.width,
                    color: Colors.blue, // full-height clickable blue area
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
                width: cameraController!.value.previewSize!.height,
                height: cameraController!.value.previewSize!.width,
                child: CameraPreview(cameraController!),
              ),
            ),
                    ),
                  ),
                ),
            
                // RIGHT clickable border
                InkWell(
                    onTap:readingMode,   
                    child: Container(
                    child: RotatedBox(quarterTurns: 3,child: Text("Reading Mode",textAlign: TextAlign.center, style: TextStyle(fontSize: 40),)),
                    height: cameraController!.value.previewSize!.width,
                    width: MediaQuery.of(context).size.width * 0.15,
                    color: Colors.blue, // full-height clickable blue area
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
                onTap: nonHistoryMode,
                onDoubleTap: historyToggleListen,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: responseText.isNotEmpty
                          ? SingleChildScrollView(
                              child: Text(
                                responseText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              isProcessing
                                  ? 'Processing...'
                                  : isListening
                                  ? 'Listening...'
                                  : recognizedWords.isNotEmpty
                                  ? 'You said: $recognizedWords'
                                  : 'Tap the mic and speak',
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
                          backgroundColor: isListening
                              ? Colors.white
                              : Colors.yellow,
                          foregroundColor: isListening
                              ? Colors.yellow
                              : Colors.white,
                          tooltip: isListening
                              ? 'Stop listening'
                              : 'Start listening',
                          elevation: 8.0,
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.yellow, width: 2),
                          ),
                          child: Icon(
                            isListening ? Icons.mic_off : Icons.mic,
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
