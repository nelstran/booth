import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage(
    this.controller,
    {super.key}
  );
  final BoothController controller;

  @override
  Widget build(BuildContext context) {
    // controller.getFriends() returns a map in the form of {'userKey': 'userName'}
    return const Scaffold(
      body: Center(
        child: Text("'Friends List View' placeholder")
      ),
    );
  }
  
}