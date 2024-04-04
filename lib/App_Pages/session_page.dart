import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/MVVM/session_model.dart';
import 'package:flutter_application_1/MVVM/student_model.dart';


/// This is the home page - where Booth Sessions appear in list view
class SessionPage extends StatelessWidget {
  SessionPage(this.user, {super.key});
  final User? user;
  final DatabaseReference _ref = FirebaseDatabase.instance.ref().child("sessions");

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
    Future<Student> student = fetchStudentInfo(user);

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
      // FirebaseAnimatedlist listens for any changes from the database reference
      body: FirebaseAnimatedList(
        query: _ref,
        itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
          // Extract data from the snapshot and convert it to a Session object
          Map data = snapshot.value as Map;
          Session session = Session(
            field: data['field'],
            level: data['level'],
            topic: data['topic'],
            currNum: data['currNum']
          );
          if(data.containsKey('maxNum')) session.maxNum = data['maxNum'];

          // Create a UI element with the converted session
          return sessionTile(context, session);
        }
      ),
    );
  }
}

// Get user info from database
Future<Student> fetchStudentInfo(User? user) async {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child("users");
  final event = await ref.once(DatabaseEventType.value);
  for (final child in event.snapshot.children){
    Map value = child.value as Map;
    if(value['uid'] == user!.uid){
      var username = (value['name'] as String).split(" ");
      return Student(username.first, username.last);
    }
  }
  return Student("", "");
}


/*
THIS WAS COPY AND PASTED FROM THE BOOTH MOCKUP, FEEL FREE TO CHANGE/REMOVE IT
THIS WAS ADDED TO MAKE SURE THE DATABASE WAS WORKING
*/
// This represents the widget itself and holds session data
Padding sessionTile(BuildContext context, Session session) {
  // If no max is specified, assume there is no limit
  String roomStr = "";
  if (session.maxNum != 0){
    roomStr = "\n[${session.currNum}/${session.maxNum}]";
  }

  return Padding(
            padding: const EdgeInsets.only(
              top: 5,
              left: 5,
              right: 5,
            ),
            child: Card( // Complicated way to add color ribbons to the listTile, not sure how to do it properly
              elevation: 2,
              child: ClipPath( // Round the corners of the ribbon
                clipper: ShapeBorderClipper(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  )
                ),
                child: Container( // This holds both the color ribbon and the listTile itself
                  // height: hei,
                  constraints: const BoxConstraints(
                    minHeight: 80,
                    maxHeight: 130,
                  ),
                  // decoration: BoxDecoration(
                  //   border: Border(
                  //     left: BorderSide(
                  //       color: session.color, 
                  //       width: 10,
                  //     )
                  //   )
                  // ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric( // Center contents inside listTile
                      vertical: 5,
                      horizontal: 15), 
                    onTap: () {},
                    shape: const RoundedRectangleBorder( // Round the corners of the listTile
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      )
                    ),
                    // Use Theme to easily change styles from one location.
                    tileColor: Theme.of(context).listTileTheme.tileColor,
                    leading: const Icon(Icons.person), //Placeholder, thinking about user profile picture
                    title: Text('${session.field} ${session.level}'),
                    subtitle: Text('Working on: ${session.topic}'),
                    trailing: Text('${session.dist} m$roomStr', textAlign: TextAlign.end,),
                    visualDensity: const VisualDensity(
                      horizontal:4,
                    ),
                  )
                ),
              )
            )
          );
  }
