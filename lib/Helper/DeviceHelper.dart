import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:papa_pro_vision/Helper/DeviceAudioHelper.dart';

class Devicehelper {
  static bool IsDevanagari(String text) {
    final devanagariRegex = RegExp(r'[\u0900-\u097F]');
    return devanagariRegex.hasMatch(text);
  }

  static Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return 'android_${androidInfo.id}_FINGER:${androidInfo.fingerprint}_HARD:${androidInfo.hardware}_SERIAL:${androidInfo.serialNumber}';
  }

  static Future<String> getOldUserDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }

  static Future<bool> hasInternetConnectionAndNotify({
    String methodCallName = "JustChecking",
  }) async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        print("Playing Internet Not Available Sound");
        await DeviceAudioHelper.playInternetNotAvailableSound();
        return false;
      }
      return true;
    } catch (e) {
      print('No internet connection, Method call : $methodCallName');
      await DeviceAudioHelper.playInternetNotAvailableSound();
      return false;
    }
  }

  static Future<Map<String, bool>> checkRegistration() async {
    try {
      var isInternetAvailable =
          await Devicehelper.hasInternetConnectionAndNotify(
            methodCallName: 'checkRegistration',
          );
      if (!isInternetAvailable) {
        print("No internet connection. Cannot perform checkRegistration.");
        return {'isRegistered': true, 'isActive': true}; //TODO Make it False!
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
        final isActive = userData['isActive'] ?? false;
        print('User status: $userData');
        return {'isRegistered': true, 'isActive': isActive};
      }

      // If not found, check with old device ID
      if (querySnapshot.docs.isEmpty) {
        final oldQuerySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('deviceId', isEqualTo: oldUserDeviceId)
            .get();
        if (oldQuerySnapshot.docs.isNotEmpty) {
          final userData = oldQuerySnapshot.docs[0].data();
          final isActive = userData['isActive'] ?? false;
          print('User status (old ID): $userData');

          // Update to new device ID
          oldQuerySnapshot.docs[0].reference.update({'deviceId': deviceId});
          return {'isRegistered': true, 'isActive': isActive};
        }
      }

      return {'isRegistered': false, 'isActive': false};
    } catch (e) {
      print('Error checking registration status: $e');
      return {'isRegistered': false, 'isActive': false};
    }
  }
}
