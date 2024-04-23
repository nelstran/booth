import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/App_Pages/expanded_session_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/session_model.dart';
import 'package:flutter_application_1/MVC/student_model.dart';

// TODO:
// Add a button that goes to the create a session page (can use Button from UI components or
// flutter's IconButton with plus symbol)
// Design the list view of sessions once a session has been created
// Get the data of a booth session and display it in each tile - done

/// This is the home page - where Booth Sessions appear in list view
class SessionPage extends StatefulWidget {
  final User? user;

  const SessionPage(this.user, {super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  // Reference to the Firebase Database sessions node
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  late final BoothController controller = BoothController(_ref);

  @override
  Widget build(BuildContext context) {
    // Get user profile before loading everything
    return FutureBuilder(
        future: controller.fetchAccountInfo(widget.user!),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return createUI();
          } else {
            return const CircularProgressIndicator(); // This isn't centered idk how to fix this
          }
        });
  }

  Scaffold createUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Booth | Welcome ${controller.student.fullname}!"),
        backgroundColor: Colors.blue,
        actions: const [
          // This button is linked to the logout method
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      // Body
      body: FirebaseAnimatedList(
        query: _ref.child("sessions"),
        // Build each item in the list view
        itemBuilder: (BuildContext context, DataSnapshot snapshot,
            Animation<double> animation, int index) {
          // Convert the snapshot to a Map
          Map<dynamic, dynamic> session =
              snapshot.value as Map<dynamic, dynamic>;

          List<String> memberNames = [];
          List<String> memberUIDs = [];

          // Here to avoid exception while debugging
          if(!session.containsKey("users")) return const SizedBox.shrink();
          Map<String, dynamic> usersInFS =
              Map<String, dynamic>.from(session['users']);
          usersInFS.forEach((key, value) {
            memberNames.add(value['name']);
            memberUIDs.add(value['uid']);
          });
          // Extract title and description from the session map
          String title = session['title'] ?? '';
          // String description = session['description']?? '';
          String description =
              session['description'] + '\n• ' + memberNames.join("\n• ");

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              child: ListTile(
                // Display title and description
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(description),
                onTap: () => {
                  // Expand session
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ExpandedSessionPage(snapshot.key!, controller),
                    ),
                  )
                },
              ),
            ),
          );
        },
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the create session page
          Navigator.pushNamed(context, '/create_session',
              arguments: {'user': controller.student});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// *********  HELPER METHODS  *****************
// This method logs the user out
void logout() {
  FirebaseAuth.instance.signOut();
}
