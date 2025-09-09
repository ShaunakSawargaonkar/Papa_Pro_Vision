import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';

class Analyticshelper {
  static Future<void> updateResponseCount(String type) async {
    var deviceId = await Devicehelper.getDeviceId();
    var temp = await FirebaseFirestore.instance
        .collection('Users')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    for (var doc in temp.docs) {
      await doc.reference.update({'Analytics.$type': FieldValue.increment(1)});
    }
  }
}
