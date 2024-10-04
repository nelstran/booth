import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/expanded_session_page.dart';
import 'package:flutter_application_1/App_Pages/search_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import '../MVC/session_model.dart';

class SessionPage extends StatelessWidget {
  const SessionPage({
    super.key,
    required this.ref,
    required this.controller,
  });

  final DatabaseReference ref;
  final BoothController controller;
  @override
  Widget build(BuildContext context) {
    List<Color> sessionColor = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green
    ];
    String institution = controller.studentInstitution;
    return Column(
      children: [
        boothSearchBar(context),
        Expanded(
          child: FirebaseAnimatedList(
            query: ref.child("institutions/$institution/sessions"),
            // Build each item in the list view
            itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {
              // Convert the snapshot to a Map
              Map<dynamic, dynamic> json = snapshot.value as Map<dynamic, dynamic>;
          
              // Here to avoid exception while debugging
              if (!json.containsKey("users")) return const SizedBox.shrink();
          
              Session session = Session.fromJson(json);
          
              List<String> memberNames = [];
              List<String> memberUIDs = [];
          
              Map<String, dynamic> usersInFS =
                  Map<String, dynamic>.from(json['users']);
              usersInFS.forEach((key, value) {
                memberNames.add(value['name']);
                memberUIDs.add(value['uid']);
              });
              // Extract title and description from the session map
              String title = json['title'] ?? '';
              // String description = session['description']?? '';
              String description =
                  json['description'] + '\n• ' + memberNames.join("\n• ");
          
              int colorIndex =
                  ((session.seatsTaken / session.seatsAvailable) * 100).floor();
              Color fullness;
              if (colorIndex <= 33) {
                fullness = sessionColor[3];
              } else if (colorIndex <= 66) {
                fullness = sessionColor[2];
              } else if (colorIndex <= 99) {
                fullness = sessionColor[1];
              } else {
                fullness = sessionColor[0];
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 2,
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(
                        color: fullness,
                        width: 10,
                      ))),
                      child: ListTile(
                        // Display title and description
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(description),
                        trailing: Text(
                          "${session.dist}m \n[${session.seatsTaken}/${session.seatsAvailable}]",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          // Expand session
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExpandedSessionPage(snapshot.key!, controller),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget boothSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showSearch(
          context: context,
          delegate: SearchPage(controller: controller),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(106, 78, 78, 78),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.white),
            SizedBox(width: 8.0),
            Text(
              'Search...',
              style: TextStyle(color: Colors.white),
            ),
            //Spacer(),
            //Icon(Icons.filter_list_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
