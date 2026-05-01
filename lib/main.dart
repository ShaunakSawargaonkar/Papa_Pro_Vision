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
import 'package:cloud_firestore/cloud_firestore.dart';
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
          var user = authSnapshot.data;
          // user = null;
          if (user == null ||
              user.phoneNumber == null ||
              user.uid.isEmpty ||
              user.phoneNumber!.isEmpty) {
            // Not signed in -> show minimal phone OTP page
            return PhoneAuthPage();
            // return RegistrationPage(phoneNumber: '9561112577', userUID: '9561112577');
            // return HomeScreen();
            // return PaymentGateway(isFirstPayment: true, userUID: '', phoneNumber: '9561112577');
            // return PaymentGateway(isFirstPayment: false);
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
                print("User status: ${snapshot.data?.userStatus}");
                final data = snapshot.data!;
                print('Referral key ID: ${data.referralKeyRef?.id}');
                if (data.userStatus == UserStatus.errorState) {
                  return AlasPage(
                    title: 'Please Contact Support',
                    message:
                        data.message ??
                        'An error occurred. Please contact support.',
                  );
                } else if (data.userStatus == UserStatus.notRegistered) {
                  return RegistrationPage(
                    phoneNumber: user.phoneNumber,
                    userUID: user.uid,
                  );
                } else if (data.userStatus == UserStatus.firstPaymentPending) {
                  return PaymentGateway(
                    isFirstPayment: true,
                    referralKeyRef: data.referralKeyRef as DocumentReference,
                    phoneNumber: user.phoneNumber ?? '',
                    userUID: user.uid,
                  );
                } else if (data.userStatus == UserStatus.paymentPending) {
                  return PaymentGateway(
                    isFirstPayment: false,
                    referralKeyRef: data.referralKeyRef as DocumentReference,
                    phoneNumber: user.phoneNumber ?? '',
                    userUID: user.uid,
                  );
                } else if (data.userStatus == UserStatus.active) {
                  return HomeScreen(userUID: user.uid);
                } else if (data.userStatus == UserStatus.noInternet) {
                  return const AlasInternetPage();
                } else if (data.userStatus == UserStatus.apkKilled) {
                  return AlasPage(
                    title: data.reasonTitle ?? 'Please update your app',
                    message:
                        data.message ??
                        'Your app version is not supported. Please update to the latest version.',
                  );
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
