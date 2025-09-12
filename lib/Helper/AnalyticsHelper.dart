import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';

class Analyticshelper {
  static Future<void> updateResponseCount(String type) async {
    var isInternetAvailable = await Devicehelper.hasInternetConnectionAndNotify(
      methodCallName: 'updateResponseCount',
    );
    if (!isInternetAvailable) {
      print("No internet connection. Cannot update response count.");
      return;
    }
    var deviceId = await Devicehelper.getDeviceId();
    var temp = await FirebaseFirestore.instance
        .collection('Users')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    for (var doc in temp.docs) {
      final docData = doc.data();

      // Check if Analytics field exists and has the specific type
      if (!docData.containsKey('Analytics') ||
          !(docData['Analytics'] as Map<String, dynamic>?)!.containsKey(type) ==
              true) {
        // Initialize the field with 0 first
        await doc.reference.update({'Analytics.$type': 0});
      }

      // Then increment by 1
      await doc.reference.update({'Analytics.$type': FieldValue.increment(1)});
    }
  }
}
