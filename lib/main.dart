import 'package:flutter/material.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasInternet.dart';
import 'package:papa_pro_vision/UI/RegisterPage/registration_page.dart';
import 'package:papa_pro_vision/UI/auth/phone_auth_page.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:papa_pro_vision/Payment/payment_gatway.dart';
import 'package:flutter/services.dart';
import 'package:papa_pro_vision/Helper/DatabaseHelper.dart';
import 'package:papa_pro_vision/enums.dart';

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = authSnapshot.data;
          if (user == null) {
            // Not signed in -> show minimal phone OTP page
            return const RegistrationPage();
            // return const PaymentGateway(isFirstPayment: true);
            // return const PaymentGateway(isFirstPayment: true);
          }
          print("User is signed in: ${user.uid} _ email: ${user.phoneNumber}");
          // Signed in -> show the existing registration/device check
          return FutureBuilder<UserStatusResponse>(
            future: DatabaseHelper.checkUserStatus(userUID: user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                final data = snapshot.data!;
                if (data.userStatus == UserStatus.errorState) {
                  return AlasPage(
                    title: 'Please Contact Support',
                    message:
                        data.message ??
                        'An error occurred. Please contact support.',
                  );
                } else if (data.userStatus == UserStatus.notRegistered) {
                  return const RegistrationPage();
                } else if (data.userStatus == UserStatus.firstPaymentPending) {
                  return const PaymentGateway(isFirstPayment: true);
                } else if (data.userStatus == UserStatus.paymentPending) {
                  return const PaymentGateway(isFirstPayment: false);
                } else if (data.userStatus == UserStatus.active) {
                  return const HomeScreen();
                } else if (data.userStatus == UserStatus.noInternet) {
                  return const AlasInternetPage();
                }
              }
              return AlasPage(
                message:
                    "Something went wrong. Please try again later or contact support.",
                title: "Something Went Wrong",
              );
            },
          );
        },
      ),
    );
  }
}
