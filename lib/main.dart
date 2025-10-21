import 'package:flutter/material.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasInternet.dart';
import 'package:provider/provider.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/UI/home_screen.dart';
import 'package:papa_pro_vision/UI/RegisterPage/registration_page.dart';
import 'package:papa_pro_vision/UI/RegisterPage/AlasPage.dart';
import 'package:firebase_core/firebase_core.dart';
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
      home: FutureBuilder<WhichPageFromMain>(
        future: Devicehelper.checkRegistration(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            if (data == WhichPageFromMain.AlasInternetPage) {
              return const AlasInternetPage();
            } else if (data == WhichPageFromMain.AlasPage) {
              return const AlasPage();
            } else if (data == WhichPageFromMain.HomeScreen) {
              return const HomeScreen();
            } else if (data == WhichPageFromMain.RegistrationPage) {
              return const RegistrationPage();
            } else {
              return const AlasInternetPage();
            }
          }
          return const AlasInternetPage();
        },
      ),
    );
  }
}
