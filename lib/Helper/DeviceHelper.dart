import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/Helper/DeviceAudioHelper.dart';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

enum WhichPageFromMain {
  AlasInternetPage,
  AlasPage,
  HomeScreen,
  RegistrationPage,
}

class Devicehelper {
  static bool IsDevanagari(String text) {
    final devanagariRegex = RegExp(r'[\u0900-\u097F]');
    return devanagariRegex.hasMatch(text);
  }

  static Future<String> getDeviceId() async {
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // String? contactNumber = await (await SharedPreferences.getInstance())
    //     .getString('contactNumber');
    // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return '_android__FINGER:_HARD:_SERIAL:';
  }

  static Future<String> getOldUserDeviceId() async {
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return '_android__FINGER:_HARD:_SERIAL:';
  }
  // static Future<String> getDeviceId() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   String? contactNumber = await (await SharedPreferences.getInstance())
  //       .getString('contactNumber');
  //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //   return '${contactNumber}_android_${androidInfo.id}_FINGER:${androidInfo.fingerprint}_HARD:${androidInfo.hardware}_SERIAL:${androidInfo.serialNumber}';
  // }

  // static Future<String> getOldUserDeviceId() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //   return androidInfo.id;
  // }

  static Future<bool> hasInternetConnectionAndNotify({
    String methodCallName = "JustChecking",
  }) async {
    try {
      // Much faster: Just check DNS resolution instead of full HTTP request
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 2));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        print("Playing Internet Not Available Sound");
        await DeviceAudioHelper.playInternetNotAvailableSound();
        return false;
      }
    } catch (e) {
      print('No internet connection, Method call : $methodCallName');
      await DeviceAudioHelper.playInternetNotAvailableSound();
      return false;
    }
  }

  static String cleanAgentResponse(String responseText) {
    return responseText.replaceAll('*', ' ').replaceAll('"', '').replaceAll('.','');
  }

  static Future<WhichPageFromMain> checkRegistration() async {
    try {
      var isInternetAvailable =
          await Devicehelper.hasInternetConnectionAndNotify(
            methodCallName: 'checkRegistration',
          );
      if (!isInternetAvailable) {
        print("No internet connection. Cannot perform checkRegistration.");
        return WhichPageFromMain.AlasInternetPage;
      }
      final deviceId = await Devicehelper.getDeviceId();
      final oldUserDeviceId = await Devicehelper.getOldUserDeviceId();
      print('Registration check: Device ID: $deviceId');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs[0].data();
        final isActive = userData['isActive'];
        print('User status: $userData');
        if (isActive) {
          return WhichPageFromMain.HomeScreen;
        } else {
          return WhichPageFromMain.AlasPage;
        }
      }

      // If not found, check with old device ID
      if (querySnapshot.docs.isEmpty) {
        final oldQuerySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('deviceId', isEqualTo: oldUserDeviceId)
            .get();
        if (oldQuerySnapshot.docs.isNotEmpty) {
          final userData = oldQuerySnapshot.docs[0].data();
          final isActive = userData['isActive'];
          print('User status (old ID): $userData');

          // Update to new device ID
          oldQuerySnapshot.docs[0].reference.update({'deviceId': deviceId});
          if (isActive) {
            return WhichPageFromMain.HomeScreen;
          } else {
            return WhichPageFromMain.AlasPage;
          }
        }
      }

      return WhichPageFromMain.RegistrationPage;
    } catch (e) {
      print('Error checking registration status: $e');
      return WhichPageFromMain.AlasInternetPage;
    }
  }

  static Future<List<Uint8List>> extractVideoFrames(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputDir = Directory(
      '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}',
    );
    await outputDir.create();

    try {
      // Extract all frames at once with 5fps filter
      final command =
          '-i "${videoFile.path}" -vf "fps=5" -y "${outputDir.path}/frame_%04d.png"';

      final session = await FFmpegKit.execute(command);

      if (ReturnCode.isSuccess(await session.getReturnCode())) {
        final frames = <Uint8List>[];

        // Read all generated frames
        final files = outputDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png'))
            .toList();

        // Sort files by name to maintain order
        files.sort((a, b) => a.path.compareTo(b.path));

        for (final file in files) {
          frames.add(await file.readAsBytes());
        }

        return frames;
      }

      return [];
    } finally {
      await outputDir.delete(recursive: true);
    }
  }
}
