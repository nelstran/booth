import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/session_model.dart';
import 'package:Booth/MVC/student_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/friend_extension.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required DatabaseReference ref,
    required this.controller,
  }) : _ref = ref;

  final DatabaseReference _ref;
  final BoothController controller;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
            flex: 0, child: Text("Place backend stuff here to test")
        ),
        // Testing friend system
        const Divider(),
        ElevatedButton(onPressed: () async {
          String school = controller.studentInstitution;
          String newSchool = school == "University of Utah" ? "Salt Lake Community College" : "University of Utah";
          Student student = controller.student;
          // First Check to see if the user is apart of any study sessions
          // If so, remove from study session
          if (student.session != "") {
            await controller.removeUserFromSession(
                student.session, student.sessionKey);
          }
          // Check is their are any sessions that they OWN and remove the session
          if (student.ownedSessionKey != "") {
            await controller.removeUserFromSession(
                student.session, student.sessionKey);
            await controller
                .removeSession(student.ownedSessionKey);
          }
          await controller.setInstitution(newSchool);
        }, child: const Text("Switch school")),
        ElevatedButton(onPressed: () async {
          final boothSession = Session(
          title: "f",
          description: "f",
          time: "1:00 PM - 2:00 PM",
          locationDescription: "f",
          seatsAvailable: 4,
          subject: "F",
          isPublic: true,
          field: "field",
          level: 1000,
          latitude: 40.7649733,
          longitude: -111.8461617,
          address: "A. Ray Olpin Student Union, , Salt Lake County, 84112",
        );

        Student student = controller.student;
        if (student.session != "") {
          await controller
              .removeUserFromSession(student.session, student.sessionKey);
        }
        controller.addSession(boothSession, student);
        }, child: Text("Add session"))
      ],
    );
  }
}
