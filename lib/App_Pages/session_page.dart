// import 'dart:js';
import 'dart:async';
// import 'dart:js_interop';
// import 'dart:js_interop';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/session_model.dart';
import 'package:flutter_application_1/MVC/student_model.dart';

// TODO:
// Add a button that goes to the create a session page (can use Button from UI components or
// flutter's IconButton with plus symbol)
// Design the list view of sessions once a session has been created
// Get the data of a booth session and display it in each tile - done

/// This is the home page - where Booth Sessions appear in list view
class SessionPage extends StatelessWidget {
  final User? user;
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  late final BoothController controller = BoothController(_ref);

  SessionPage(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    // Get user profile before loading everything
    return FutureBuilder(
        future: controller.fetchAccountInfo(user!),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return createUI();
          } else {
            return const CircularProgressIndicator(); // This isn't centered idk how to fix this
          }
        });
  }

  Scaffold createUI() {
    // Go to firebase console to see effects
    Student testStudent =
        Student(uid: "000", firstName: "Jane", lastName: "Doe");
    Session testSession =
        Session(field: "TEST", level: 1234, topic: "DEBUGGING", memberIds: []);
    // Session testSession = Session(
    //     field: "AddToThisSession",
    //     level: 5678,
    //     topic: "addUsers",
    //     memberIds: []);

    return Scaffold(
      appBar: AppBar(
        // This is the top banner
        title:
            Text("{DEBUG} Welcome ${controller.student.fullname}! "), // DEBUG
        // title: const Text("Booth"),
        backgroundColor: Colors.blue,
        actions: const [
          // This button is linked to the logout method
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      // FirebaseAnimatedlist listens for any changes from the database reference
      body: FirebaseAnimatedList(
          query: _ref.child("sessions"),
          itemBuilder: (BuildContext context, DataSnapshot snapshot,
              Animation<double> animation, int index) {
            // Extract data from the snapshot and convert it to a Session object
            Map data = snapshot.value as Map;

            final user = FirebaseAuth.instance.currentUser;

            List<Student> members = [];

            Map<String, dynamic> usersInFS =
                Map<String, dynamic>.from(data['users']);
            usersInFS.forEach((key, value) {
              members.add(Student(
                uid: value['uid'],
                firstName: value['name'],
                lastName: value['name'],
              ));
            });

            Session session = Session(
                key: snapshot.key!,
                field: data['field'],
                level: data['level'],
                topic: data['topic'],
                currNum: data['currNum'],
                memberIds: _memberIds(user, members));
            if (data.containsKey('maxNum')) session.maxNum = data['maxNum'];

            // Create a UI element with the converted session
            return sessionTile(context, session);
          }),
      floatingActionButton: debugOptions(testStudent, testSession), //DEBUG
    );
  }

  // Get the member ids from the session data
  List<Student> _memberIds(User? user, List<Student> members) {
    // List<Student> ids = [user.uid];
    List<Student> ids = [];

    for (Student member in members) {
      ids.add(member);
    }

    //Removes duplicates
    return {...ids}.toList();
  }

  Column debugOptions(Student testStudent, Session testSession) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text("These buttons do something, check on the firebase console"),
        ListTile(
            title: const Text("ADD STUDENT (Jane Doe)"),
            onTap: () {
              controller.addUser(testStudent);
            }),
        ListTile(
            title: const Text("REMOVE STUDENT (need key)"),
            onTap: () {
              // Add then retrieve key from firebase website and update
              controller.removeUser("-NuglrdPoPgwR0Sf1lQL");
            }),
        ListTile(
            title: const Text("ADD SESSION W/ USER"),
            onTap: () {
              controller.addSession(testSession, controller.student);
            }),
        ListTile(
            title: const Text("REMOVE SESSION (need key)"),
            onTap: () {
              // Add then retrieve key from firebase website and update
              controller.removeSession("-Nuopv_-AzloqIvgZqJt");
            }),
        ListTile(
            title: const Text("ADD STUDENT TO SESSION (need Key)"),
            //Needs a session key for the user to be added to
            onTap: () {
              controller.addUserToSession(
                  "-NupNXNRmFQR85iXsUym", createRandomStudent());
            }),
        ListTile(
            title: const Text(
                "REMOVE STUDENT FROM SESSION (need student and sesh key)"),
            //Needs a session key for the user to be added to
            onTap: () {
              controller.removeUserFromSession(
                  "-NupNXNRmFQR85iXsUym", "-NuqhkIxNavQFw4bA7Z4");
            }),
      ],
    );
  }

  /*
  ------------------------------------------------------------------------------
  sessionTile was copy and pasted from the booth mockup, feel
  free to change/remove it. Used for debugging purposes
  ------------------------------------------------------------------------------
  */
  // This represents the widget itself and holds session data
  Padding sessionTile(BuildContext context, Session session) {
    // If no max is specified, assume there is no limit
    String roomStr = "";
    if (session.maxNum != 0) {
      roomStr = "\n[${session.currNum}/${session.maxNum}]";
    }

    return Padding(
        padding: const EdgeInsets.only(
          top: 5,
          left: 5,
          right: 5,
        ),
        child: Card(
            // Complicated way to add color ribbons to the listTile, not sure how to do it properly
            elevation: 2,
            child: ClipPath(
              // Round the corners of the ribbon
              clipper: ShapeBorderClipper(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Container(
                  // This holds both the color ribbon and the listTile itself
                  // height: hei,
                  constraints: const BoxConstraints(
                    minHeight: 80,
                    maxHeight: 130,
                  ),
                  decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                    color: Colors
                        .green, // TO DO: change colors depending on how full it is
                    width: 10,
                  ))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        // Center contents inside listTile
                        vertical: 5,
                        horizontal: 15),
                    onTap: () {},
                    shape: const RoundedRectangleBorder(
                        // Round the corners of the listTile
                        borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    )),
                    // Use Theme to easily change styles from one location.
                    tileColor: Theme.of(context).listTileTheme.tileColor,
                    leading: const Icon(Icons
                        .person), //Placeholder, thinking about user profile picture
                    title: Text('${session.field} ${session.level}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Working on: ${session.topic}'),
                        Text("Members Num: ${session.memberIds.length}"),
                        for (Student member in session.memberIds)
                          Text(member.firstName),
                      ],
                    ),
                    trailing: Text(
                      '${session.dist} m$roomStr',
                      textAlign: TextAlign.end,
                    ),
                    visualDensity: const VisualDensity(
                      horizontal: 4,
                    ),
                  )),
            )));
  }
}

/// *********  HELPER METHODS  *****************
// This method logs the user out
void logout() {
  FirebaseAuth.instance.signOut();
}

Student createRandomStudent() {
  final Random random = Random();

  List<String> firstNames = ["Brayden", "Leena", "Joel", "Nelson", "James"];
  List<String> lastNames = ["Neal", "Butt", "Guillen", "Tran", "Germaine"];

  String uid = random.nextInt(1000).toString().padLeft(3, '0');
  String firstName = firstNames[random.nextInt(firstNames.length)];
  String lastName = lastNames[random.nextInt(lastNames.length)];

  return Student(uid: uid, firstName: firstName, lastName: lastName);
}
