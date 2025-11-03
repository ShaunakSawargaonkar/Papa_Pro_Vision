import 'package:flutter/material.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasInternet.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/UI/home_screen.dart';
import 'package:papa_pro_vision/UI/RegisterPage/registration_page.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:papa_pro_vision/UI/auth/phone_auth_page.dart';
// import 'package:papa_pro_vision/Payment/payment_gateway.dart';  // Temporarily disabled
import 'package:papa_pro_vision/Payment/payment_module.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConversationController(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      // Show Phone OTP flow when not signed in. When signed in, keep the
      // original FutureBuilder that chooses the correct app page.
      home: PaymentGateway(
        currentDate: DateTime.now(),
        email: "<user_email>",
        mobileNo: "<user_mobile_no>",
        userName: "<user_name>",
      ), // Temporarily using PhoneAuthPage instead of PaymentGateway
      // StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, authSnapshot) {
      //     if (authSnapshot.connectionState == ConnectionState.waiting) {
      //       return const Scaffold(
      //         body: Center(child: CircularProgressIndicator()),
      //       );
      //     }

      //     final user = authSnapshot.data;
      //     if (user == null) {
      //       // Not signed in -> show minimal phone OTP page
      //       return const PhoneAuthPage();
      //     }
      //     print("User is signed in: ${user.uid} _ email: ${user.phoneNumber}");
      //     // Signed in -> show the existing registration/device check
      //     return FutureBuilder<WhichPageFromMain>(
      //       future: Devicehelper.checkRegistration(),
      //       builder: (context, snapshot) {
      //         if (snapshot.connectionState == ConnectionState.waiting) {
      //           return const Scaffold(
      //             body: Center(child: CircularProgressIndicator()),
      //           );
      //         }
      //         if (snapshot.hasData) {
      //           final data = snapshot.data!;
      //           if (data == WhichPageFromMain.AlasInternetPage) {
      //             return const AlasInternetPage();
      //           } else if (data == WhichPageFromMain.AlasPage) {
      //             return const AlasPage();
      //           } else if (data == WhichPageFromMain.HomeScreen) {
      //             return const HomeScreen();
      //           } else if (data == WhichPageFromMain.RegistrationPage) {
      //             return const RegistrationPage();
      //           } else {
      //             return const AlasInternetPage();
      //           }
      //         }
      //         return const AlasInternetPage();
      //       },
      //     );
      //   },
      // ),
    );
  }
}

// Phone auth page moved to `lib/UI/auth/phone_auth_page.dart`.
