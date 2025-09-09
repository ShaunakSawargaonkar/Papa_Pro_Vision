import 'package:device_info_plus/device_info_plus.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class Devicehelper {
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

  static Future<Map<String, bool>> checkRegistration() async {
    try {
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
