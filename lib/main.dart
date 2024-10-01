import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/create_profile_page.dart';
import 'package:flutter_application_1/User_Authentication/auth.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/App_Theme/dark_mode.dart';

/// The main page where the app initializes
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Show authentication page first (auth.dart)
      home: const AuthPage(),
      routes: {
        '/main_ui_page': (context) => const AuthPage(),
        '/create_profile': (context) => const CreateProfilePage(),
      },
      // Change the theme of the app to light or dark mode depending on system settings
      theme: darkMode,
      // darkTheme: darkMode,
    );
  }
}
