import 'package:amplitude_flutter/amplitude.dart';
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
    required DatabaseReference ref,
    required this.controller,
  }) : _ref = ref;

  final DatabaseReference _ref;
  final BoothController controller;

  @override
  Widget build(BuildContext context) {
    return FirebaseAnimatedList(
      query: _ref.child("sessions"),
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
    
        return Column(
          children: [
            if (index == 0) boothSearchBar(context),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                clipBehavior: Clip.antiAlias,
                // color: Colors.black38,
                elevation: 0,
                child: ListTile(
                  // Display title and description
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  subtitle: Text(description),
                  trailing: Text(
                    "${session.dist}m \n[${session.seatsTaken}/${session.seatsAvailable}]",
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    Amplitude.getInstance().logEvent("Session Clicked");
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
          ],
        );
      },
    );
  }

  SearchBar boothSearchBar(context){
    return SearchBar(
      onSubmitted: (value) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchPage(value),
          ),
        );
      },
      leading: const IntrinsicHeight(
        child: Row(
          children: [
            Icon(Icons.search),
            VerticalDivider(color: Colors.black,)
          ],
        ),
      ),
      trailing: [
        ElevatedButton(
          onPressed: (){},
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              Colors.transparent
            )
          ),
          child: const Icon(
            Icons.filter_list_rounded,
            color: Colors.white
          ),
        )
      ],
      shadowColor: const WidgetStatePropertyAll(
        Colors.transparent
      ),
      backgroundColor: const WidgetStatePropertyAll(
        Color.fromARGB(106, 78, 78, 78),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.zero)
        )
      )
    );
  }
}