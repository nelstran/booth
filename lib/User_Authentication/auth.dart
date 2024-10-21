import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Booth/App_Pages/main_ui_page.dart';
import 'package:Booth/User_Authentication/login_or_register.dart';

/// This class authenticates the user, making sure they are an existing user
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    LoginOrRegister loginOrRegister = LoginOrRegister();
    return Scaffold(
      // Keeps nav bar in place when keyboard is up
      resizeToAvoidBottomInset: false,
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user exists in the database, display the home page (Sessions Page)
          if (snapshot.hasData) {
            var showLoginPage = loginOrRegister.showLoginPage;
            return MainUIPage(snapshot.data, showLoginPage);
          }
          // Otherwise, display the login or register page
          else {
            return loginOrRegister;
          }
        },
      ),
    );
  }
}
