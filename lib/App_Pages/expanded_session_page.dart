import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class ExpandedSessionPage extends StatefulWidget {
  final BoothController controller;
  final String sessionKey;
  const ExpandedSessionPage(this.sessionKey, this.controller, {super.key});

  @override
  _ExpandedSessionPageState createState() => _ExpandedSessionPageState();
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
            flex: 8, // Dictates how much space they take

            // Replace container with your UI
            child: Container(color: Colors.grey.shade800, child: const Text("Details Placeholder"))
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
                if (isInThisSession) {
                  controller.removeUserFromSession(widget.sessionKey, controller.student.sessionKey);
                }
                else {
                  controller.addUserToSession(widget.sessionKey, controller.student);
                }
                isInThisSession = !isInThisSession; // Janky way to update state UI
                updateState();
                // isInThisSession = controller.student.session == widget.sessionKey;
              });
            },
          )
        )
      ),
    );
  }
}