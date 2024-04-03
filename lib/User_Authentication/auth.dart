import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/User_Authentication/login_or_register.dart';
import 'package:flutter_application_1/App_Pages/session_page.dart';

/// This class authenticates the user, making sure they are an existing user
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user exists in the database, display the home page (Sessions Page)
          if (snapshot.hasData) {
            return SessionPage();
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