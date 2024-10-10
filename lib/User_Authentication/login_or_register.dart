import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/login_page.dart';
import 'package:flutter_application_1/App_Pages/register_page.dart';

/// This class allows for a switch between the login and register pages
class LoginOrRegister extends StatefulWidget {
  LoginOrRegister({super.key});

  // Show the login page first
  bool showLoginPage = true;
  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  

  // Toggle between login and register page
  void togglePages() {
    setState(() {
      widget.showLoginPage = !widget.showLoginPage;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if(widget.showLoginPage){
      return LoginPage(onTap: togglePages);
    } else {
      return RegisterPage(onTap: togglePages);
    }
  }
}