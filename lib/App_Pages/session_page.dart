import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// This is the home page - where Booth Sessions appear in list view
class SessionPage extends StatelessWidget {
  const SessionPage({super.key});

  // This method logs the user out
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  // TODO:
  // Add a button that goes to the create a session page (can use Button from UI components or
  // flutter's IconButton with plus symbol)
  // Design the list view of sessions once a session has been created
  // Get the data of a booth session and display it in each tile
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This is the top banner 
        title: Text("Booth"),
        backgroundColor: Colors.blue,
        actions: [
          // This button is linked to the logout method
          IconButton(
            onPressed: logout, 
            icon: Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}