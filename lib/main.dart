import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/create_session_page.dart';
import 'package:flutter_application_1/User_Authentication/auth.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/App_Theme/dark_mode.dart';

/// The main page where the app initializes
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Amplitude analytics = Amplitude.getInstance(instanceName: "Booth");
  analytics.init('8e9f2f83987da4fd6bbc90afcac6bbb6');
  analytics.logEvent('MyApp startup', eventProperties:{});
  
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
        '/create_session': (context) => CreateSessionPage(),
      },
      // Change the theme of the app to light or dark mode depending on system settings
      theme: darkMode,
      // darkTheme: darkMode,
    );
  }

}