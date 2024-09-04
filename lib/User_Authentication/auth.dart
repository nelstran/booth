import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/App_Pages/main_ui_page.dart';
import 'package:flutter_application_1/User_Authentication/login_or_register.dart';

/// This class authenticates the user, making sure they are an existing user
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keeps nav bar in place when keyboard is up
      resizeToAvoidBottomInset: false,
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user exists in the database, go to main page (should start at Session page)
          if (snapshot.hasData) {
            return MainPage(snapshot.data);
          }
          // Otherwise, display the login or register page
          else{
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}