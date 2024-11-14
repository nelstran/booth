import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/login_page.dart';
import 'package:Booth/App_Pages/register_page.dart';
import 'package:flutter/services.dart';

/// This class allows for a switch between the login and register pages
class LoginOrRegister extends StatefulWidget {
  LoginOrRegister({super.key});
  bool inLoginPage = true;

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  late PageController pageController;
  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
    var loginPage = LoginPage(onTap: togglePages);
    var registerPage = RegisterPage(onTap: togglePages);
    pages = [
      loginPage,
      registerPage
    ];
  }
  // Toggle between login and register page
  void togglePages() {
    setState(() {
      widget.inLoginPage = !widget.inLoginPage;
      pageController.animateToPage(
        widget.inLoginPage ? 0 : 1, 
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeOutExpo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop){
          return;
        }
        if (!widget.inLoginPage){
          togglePages();
        }
        else{
          // If user clicks back, exit app
          if (Platform.isAndroid){
            // Works only on android
            SystemNavigator.pop();
          }
          else if (Platform.isIOS){
            // On iOS, calls to this method are ignored because Apple's
            // human interface guidelines state that applications
            // should not exit themselves.
          }
        }
      },
      child: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        children: pages
      ),
    );
  }
}
