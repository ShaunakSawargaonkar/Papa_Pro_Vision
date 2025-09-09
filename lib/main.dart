import 'package:flutter/material.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:papa_pro_vision/UI/RegisterPage/registration_page.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConversationController(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, bool>> _checkRegistration() async {
    try {
      final deviceId = await Devicehelper.getDeviceId();
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
      return {'isRegistered': false, 'isActive': false};
    } catch (e) {
      print('Error checking registration status: $e');
      return {'isRegistered': false, 'isActive': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Papa ProVision',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Map<String, bool>>(
        future: _checkRegistration(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            final isRegistered = data['isRegistered'] ?? false;
            final isActive = data['isActive'] ?? false;

            if (isRegistered && !isActive) {
              return const AlasPage();
            } else if (isRegistered && isActive) {
              return const HomeScreen();
            }
          }

          return const RegistrationPage();
        },
      ),
    );
  }
}
