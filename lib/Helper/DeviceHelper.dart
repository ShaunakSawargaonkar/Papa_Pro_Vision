import 'package:device_info_plus/device_info_plus.dart';

class Devicehelper {
  static Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return 'android_${androidInfo.id}_FINGER:${androidInfo.fingerprint}_HARD:${androidInfo.hardware}_SERIAL:${androidInfo.serialNumber}';
  }
}
