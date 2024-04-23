import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

import '../MVC/session_model.dart';

class ExpandedSessionPage extends StatefulWidget {
  final BoothController controller;
  final String sessionKey;
  const ExpandedSessionPage(this.sessionKey, this.controller, {super.key});

  @override
  State<ExpandedSessionPage> createState() { return  _ExpandedSessionPageState();}
}

class _ExpandedSessionPageState extends State<ExpandedSessionPage> {
  late BoothController controller = widget.controller;
  late bool isInThisSession;
  late Color buttonColor;

  @override
  void initState() {
    super.initState();
    isInThisSession = controller.student.session == widget.sessionKey;
    updateState(); 
  }

  updateState(){
    buttonColor = (isInThisSession ? Colors.red[900] : Colors.green[800])!;
  }

  @override
  Widget build(BuildContext context) {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Session Info
          // TODO: Display the information that was not previously in the main page
          Expanded(
            flex: 8, // Dictates how much space this will take
            child: StreamBuilder(
              stream: _ref.child("sessions/${widget.sessionKey}").onValue,
              builder: (context, snapshot) {
                if(snapshot.hasData && snapshot.data!.snapshot.value != null){
                  Map<dynamic, dynamic> json = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  Session session = Session.fromJson(json);

                  // Replace container with your UI
                  return Container(color: Colors.grey.shade800, child: const Text("Details Placeholder"));
                }
                else{
                  return const CircularProgressIndicator();
                }
              },
            )
          ),

          // Show students in the session
          // TODO (Optional??): Show a scrollable list of students currently in the session
          // Expanded(
          //   flex: 2,
          //   child: Container(color: Colors.grey.shade700, child: Text("Lobby Placeholder"))
          // ),

          // Button to join and leave the session
          Expanded(
            flex: 1,
            child: joinLeaveButton() // Extracted UI to method to keep things simple
          )
        ],
      )
    );
  }

  Padding joinLeaveButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: const BorderRadius.all(Radius.circular(10))
        ),
        child: Center(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size.fromWidth(double.infinity),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            child:Text(isInThisSession ? "Leave" : "Join"),
            onPressed: (){
              setState(() {
                if (controller.student.ownedSessionKey != "")
                {
                  controller.removeSession(controller.student.ownedSessionKey);
                }
                if (isInThisSession) {
                  controller.removeUserFromSession(widget.sessionKey, controller.student.sessionKey);
                }
                else {
                  controller.addUserToSession(widget.sessionKey, controller.student);
                }
                isInThisSession = !isInThisSession; // Janky way to update state UI
                updateState();
                // isInThisSession = controller.student.session == widget.sessionKey; // This does not work on first click
              });
            },
          )
        )
      ),
    );
  }
}