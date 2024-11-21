import 'package:Booth/App_Pages/expanded_session_page.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/student_model.dart';
import 'package:flutter/material.dart';
import 'package:Booth/MVC/booth_controller.dart';
import '../MVC/session_model.dart';
import 'package:Booth/MVC/saved_sessions_extension.dart';

/// UI to display the list of session the user decides
/// to archive and reuse for later
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
    return Scaffold(
        body: StreamBuilder(
        stream: widget.controller.savedSessionRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          var savedSessionsList = [];
          var savedSessionKeys = [];
          for(var document in snapshot.data!.docs){
            savedSessionKeys.add(document.id);
            savedSessionsList.add(document.data());
          }
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
                      Session rehostedSession = Session.fromJson(savedSessionsList[index]);
                      String sessionKey = savedSessionKeys[index];
                      rehostedSession.key = "";
                      return savedSessionTile(userKey, sessionKey, rehostedSession);
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

  ListTile savedSessionTile(String userKey, String savedSessionKey, Session savedSession) {
    return  ListTile(
        // Display title and description
        title: Text(
          savedSession.title,
          style: const TextStyle(
              fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(savedSession.locationDescription),
            const SizedBox(height: 2),
          ],
        ),
        trailing: Wrap(
          spacing: 5,
          children: <Widget>[
          rehostButton(savedSession, context),
          IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _handleDeleteSession(savedSessionKey, savedSession),
          )
          ],
      ),
      onTap: () { 
          // navigate to session details to view more
          //  Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => SessionDetailsPage(),
          //   ),
          // );
      }
    );
  }

  ElevatedButton rehostButton(Session savedSession, BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
      shape: const StadiumBorder(),
      ),
      onPressed: () => _handleRehostButton(savedSession),
      label: const Text("Rehost"),
    );
  }

  /// Confirm with users if they would like to delete their archived session
  void _handleDeleteSession(String sessionKey, Session session) async {
    await showDialog(
          context: context, 
          builder: (context){
            return AlertDialog(
          title: const Text(
            "Confirmation",
          ),
          content: Text("Are you sure you would like to delete '${session.title}'?"),
          actions:[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                    ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                ElevatedButton(
                  onPressed: (){
                    widget.controller.unsaveSession(widget.controller.student.uid, sessionKey);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero
                      ),
                  child: const Text(
                    "Delete forever",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                
              ],
            )
          ]
        );
      }
    );
  }

  /// Confirm with users if they would like to create a new session from the history list
  Future<void> _handleRehostButton(Session session) async {
      await showDialog(
          context: context, 
          builder: (context){
            return AlertDialog(
          title: const Text(
            "Create Study Session?",
          ),
          content: Text("Would you like to open up '${session.title}'"),
          actions:[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.only(right: 16)
                      ),
                  child: const Text(
                    "Nevermind",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _addSavedSession(session),
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      // shadowColor: Colors.transparent,
                      // backgroundColor: Colors.transparent,
                    ),
                  child: const Text(
                    "Create session",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ]
        );
      }
    );
  }

  /// If users confirm to create a session, add the selected session to the 
  /// database and direct the user to its page
  Future<void> _addSavedSession(Session session) async {
    Navigator.of(context).pop(); // Pop Dialog
    // Display loading circle
    showDialog(
      barrierDismissible: false,
      context: context, 
      builder: (context){
        return const Center(child: CircularProgressIndicator());
      }
    );
    // First Check to see if the user is apart of any study sessions
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
    await widget.controller.addSession(session ,widget.controller.student);

    if(!mounted) return;
    // Pop Loading circle
    Navigator.of(context).pop();
    // Open up the session page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ExpandedSessionPage(widget.controller.student.ownedSessionKey, widget.controller),
      ),
    );
    
  }
}
