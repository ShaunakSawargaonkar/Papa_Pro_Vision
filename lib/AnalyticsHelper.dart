import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Analyticshelper {
  static Future<void> updateResponseCount(String type) async {
    var deviceId = await _getDeviceId();
    var temp = await FirebaseFirestore.instance
        .collection('Users')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    for (var doc in temp.docs) {
      await doc.reference.update({'Analytics.$type': FieldValue.increment(1)});
    }
  }

  static Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }
}
