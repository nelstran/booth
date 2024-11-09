import 'package:Booth/firebase_msg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:Booth/User_Authentication/auth.dart';
import 'package:Booth/firebase_options.dart';
import 'package:Booth/App_Theme/dark_mode.dart';

/// The main page where the app initializes
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMsg().initNotifications();
  //await FirebaseMsg.initPushNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Firebase Messaging notifications handling
    final firebaseMsg = FirebaseMsg();
    firebaseMsg.initNotifications();
    firebaseMsg.initPushNotifications(context);  // Pass the context here

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Show authentication page first (auth.dart)
      home: const AuthPage(),
      routes: {
        '/main_ui_page': (context) => const AuthPage(),
      },
      // Change the theme of the app to light or dark mode depending on system settings
      theme: darkMode,
      // darkTheme: darkMode,
    );
  }
}
