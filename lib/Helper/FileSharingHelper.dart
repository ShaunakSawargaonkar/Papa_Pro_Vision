import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FileSharingHelper {
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  void intentSubListener(List<SharedMediaFile> value, ConversationController controller) async {
    final prefs = await SharedPreferences.getInstance();
    _sharedFiles.clear();
    _sharedFiles.addAll(value);
    print('Shared File: ${_sharedFiles.map((f) => f.toMap())}');
    await processSharedImage(controller, prefs.getString('inputLanguage') ?? 'en_IN', prefs.getBool('enableTranslation') ?? false);
    ReceiveSharingIntent.instance.reset();
  }

  void initialize(ConversationController controller) {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) async {
        intentSubListener(value, controller);
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
        intentSubListener(value, controller);
      });
  }

  void dispose() {
    _intentSub.cancel();
  }

  Future<void> processSharedImage(ConversationController controller, String inputLanguage, bool enableTranslation) async {
    if (_sharedFiles.isNotEmpty) {
      // Only process the first shared file
      SharedMediaFile sharedFile = _sharedFiles.first;

      try {
        // Get the file path from the shared media file
        String? filePath = sharedFile.path;

        if (filePath != null) {   
          // Read the image file as bytes
          File imageFile = File(filePath);
          Uint8List imageBytes = await imageFile.readAsBytes();
          print('Uploaded Image Bytes: ${imageBytes.length}');
          controller.setUploadedImageMode(imageBytes, inputLanguage, enableTranslation);
          
        }
      } catch (e) {
        print('Error processing shared image: $e');
      }
    }
  }

}