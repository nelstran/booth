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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: StreamBuilder(
                stream: _ref.child("sessions/${widget.sessionKey}").onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> json = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    Session session = Session.fromJson(json);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          'Description: ${session.description}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          'Location Description: ${session.locationDescription}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 18.0),
                            const SizedBox(width: 5.0),
                            Text(
                              'Time: ${session.time}',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 18.0),
                            const SizedBox(width: 5.0),
                            Text(
                              'Seats Available: ${session.seatsAvailable - session.seatsTaken}',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            const Icon(Icons.subject, size: 18.0),
                            const SizedBox(width: 5.0),
                            Text(
                              'Subject: ${session.subject}',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                      ],
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Students in Session:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Expanded(
              flex: 3,
              child: StreamBuilder(
                stream: _ref.child("sessions/${widget.sessionKey}/users").onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> json = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List<String> memberNames = json.values.map((value) => value['name'] as String).toList();

                    return ListView.builder(
                      itemCount: memberNames.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            memberNames[index],
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        );
                      },
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
            // Button to join and leave the session
            Expanded(
              flex: 1,
            child: joinLeaveButton() // Extracted UI to method to keep things simple
          )
          ],
        ),
      ),
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
                // ------ THIS INTERRUPTS THE BUTTON FUNCTIONALITY ------
                if (controller.student.ownedSessionKey != "")
                {
                  controller.removeSession(controller.student.ownedSessionKey);
                }
                // -------------------------------------------------------
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