import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// This is the home page - where Booth Sessions appear in list view
class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  _SessionPageState createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  // Reference to the Firebase Database sessions node
  final DatabaseReference _sessionsRef = FirebaseDatabase.instance.reference().child('sessions');

  // This method logs the user out
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booth"),
        backgroundColor: Colors.blue,
        actions: [
          // Logout Button
          IconButton(
            onPressed: logout, 
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      // Body
      body: FirebaseAnimatedList(
        query: _sessionsRef,
        // Build each item in the list view
        itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
          // Convert the snapshot to a Map
          Map<dynamic, dynamic> session = snapshot.value as Map<dynamic, dynamic>;
          // Extract title and description from the session map
          String title = session['title']?? '';
          String description = session['description']?? '';

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
              ),
            ),
          );
        },
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the create session page
          Navigator.pushNamed(context, '/create_session');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}