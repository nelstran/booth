import 'package:Booth/App_Pages/session_details_page.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/student_model.dart';
import 'package:Booth/UI_components/focus_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/expanded_session_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import '../MVC/session_model.dart';
import 'package:Booth/MVC/saved_sessions_extension.dart';

class SavedSessionsPage extends StatefulWidget {
  const SavedSessionsPage(this.controller, {super.key});
  final BoothController controller;

  @override
  State<SavedSessionsPage> createState() => _SavedSessionsPage();
}

class _SavedSessionsPage extends State<SavedSessionsPage>{
  @override
  Widget build(BuildContext context) {
    String userKey = widget.controller.student.uid;
    Future<Map<dynamic, dynamic>> savedSessions = widget.controller.fetchuserSavedSessions(userKey);
    var savedSessionsList = {};
    return Scaffold(
        body: FutureBuilder(
        future: savedSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          savedSessionsList = snapshot.data!;
        
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Saved Sessions",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (savedSessionsList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: savedSessionsList.length,
                    itemBuilder: (context, index) {
                      return savedSessionTile(userKey, savedSessionsList.keys.toList()[index], savedSessionsList.values.toList()[index]);
                   }
                 ),
                )
              else
                const Center(child: Text('No saved sessions found'))
            ],
          );
        }
      )
    );
  }

  ListTile savedSessionTile(userKey, savedSessionKey, savedSession) {
       return  ListTile(
              // Display title and description
              title: Text(
                savedSession["title"],
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(savedSession["locationDescription"]),
                  const SizedBox(height: 2),
                ],
              ),
              trailing: Wrap(
                spacing: 5,
                children: <Widget>[
                rehostButton(savedSession, context),
                IconButton(
                icon: Icon(Icons.delete),
                onPressed: () { 
                    widget.controller.unsaveSession(userKey, savedSessionKey);
                    setState(() {});
                },
                )
                ],
            ),
            onTap: () { 
                // navigate to session details to view more
            //      Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => SessionDetailsPage(),
            //       ),
            //     );
            }
    );
  }

  ElevatedButton rehostButton(savedSession, BuildContext context) {
    return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
          shape: StadiumBorder(),
          ),
          onPressed: () async {
           //First Check to see if the user is apart of any study sessions
          // If so, remove from study session
          Student student = widget.controller.student;
          if (student.session != "") {
            await widget.controller.removeUserFromSession(
                student.session, student.sessionKey);
          }
          // Check if there are any sessions that they OWN and remove the session
          if (student.ownedSessionKey != "") {
            await widget.controller.removeUserFromSession(
                student.session, student.sessionKey);
            await widget.controller
                .removeSession(student.ownedSessionKey);
          }
            Session rehostedSession = Session.fromJson(savedSession);
            rehostedSession.key = "";
            widget.controller.addSession(rehostedSession,widget.controller.student);
          },
          label: const Text("Rehost"),
        );
  }
}
