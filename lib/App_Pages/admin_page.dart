import 'package:Booth/MVC/profile_extension.dart';
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
          controller.updateUserProfile({"institution": newSchool});
          controller.setInstitution(newSchool);
        }, child: const Text("Switch school"))
      ],
    );
  }
}
