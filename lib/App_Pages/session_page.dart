import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/expanded_session_page.dart';
import 'package:flutter_application_1/App_Pages/filter_ui.dart';
import 'package:flutter_application_1/App_Pages/search_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/profile_extension.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../MVC/session_model.dart';

class SessionPage extends StatefulWidget {
  final DatabaseReference ref;
  final BoothController controller;
  const SessionPage({
    super.key,
    required this.ref,
    required this.controller,
  });
  
  @override
  State<SessionPage> createState() => _SessionPage();
}
class _SessionPage extends State<SessionPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Map filters = {};
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<Color> sessionColor = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green
    ];
    
    return Column(
      children: [
        boothSearchBar(context),
        Expanded(
          // Update list of sessions when user changes schools
          child: StreamBuilder(
            stream: widget.controller.profileRef.child("institution").onValue,
            builder: (context, snap){
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              String institution = widget.controller.studentInstitution;
              return FirebaseAnimatedList(
                key: Key(institution),
                query: widget.controller.sessionRef,
                // Build each item in the list view
                itemBuilder: (BuildContext context, DataSnapshot snapshot,
                    Animation<double> animation, int index) {
                  // Convert the snapshot to a Map
                  Map<dynamic, dynamic> json = snapshot.value as Map<dynamic, dynamic>;
              
                  // Here to avoid exception while debugging
                  if (!json.containsKey("users")) return const SizedBox.shrink();
              
                  Session session = Session.fromJson(json);
                  if (isFiltered(session)){
                    return const SizedBox.shrink();
                  }
              
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
                  String description = json['description'] ?? '';
              
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
              
                  // Control the max number of users to display on the front page
                  int numOfPFPs = 4;
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              // Show list and the people in that session represented by their pfp
                              children: [
                                Text(description),
                                const SizedBox(height: 2),
                                rowOfPFPs(memberNames, numOfPFPs, memberUIDs)
                              ],
                            ),
                            trailing: Text(
                              "[${session.seatsTaken}/${session.seatsAvailable}]",
                              textAlign: TextAlign.center,
                            ),
                            onTap: () {
                              // Expand session
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExpandedSessionPage(snapshot.key!, widget.controller),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }

  SizedBox rowOfPFPs(List<String> memberNames, int numOfPFPs, List<String> memberUIDs) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: memberNames.length > numOfPFPs ? numOfPFPs : memberNames.length,
        itemBuilder: (context, index) {
          var pfpRadius = 15.0;
          var pfpFontSize = 13.0;
          return Row(
            children: [
              StreamBuilder(
                stream: widget.controller.pfpRef(memberUIDs[index]).snapshots(), 
                builder:(context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData
                  ){
                    return Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ProfilePicture(
                        name: memberNames[index], 
                        radius: pfpRadius, 
                        fontsize: pfpFontSize
                      ),
                    );
                  }
                  return FutureBuilder(
                    future: widget.controller.getProfilePictureByUID(memberUIDs[index]), 
                    builder:(context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError){
                        return Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: pfpRadius,
                            child: SizedBox(
                              height: pfpRadius,
                              width: pfpRadius,
                              child: const CircularProgressIndicator()),
                          )
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: ProfilePicture(
                            name: memberNames[index], 
                            radius: pfpRadius, 
                            fontsize: pfpFontSize,
                            img: snapshot.data,
                          ),
                      );
                    },
                  );
                },
              ),
              if (memberNames.length > numOfPFPs && index == numOfPFPs - 1) 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "+${memberNames.length - numOfPFPs}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ) 
              else const SizedBox.shrink()
            ],
          );
        },
      ),
    );
  }

  Widget boothSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showSearch(
          context: context,
          delegate: SearchPage(controller: widget.controller),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(106, 78, 78, 78),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white),
            const SizedBox(width: 8.0),
            const Text(
              'Search...',
              style: TextStyle(color: Colors.white),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: const Color.fromARGB(255, 22, 22, 22)
                      ),
                      onPressed: (){
                        showModalBottomSheet(
                          showDragHandle: true,
                          isScrollControlled: true,
                          context: context, 
                          builder: (context){
                            return Wrap(
                              children: [
                                FilterUI(filters)
                              ]);
                          })
                          // After users apply filters, values will show up here
                          .then((value) {
                            setState((){
                              filters = value;
                            });
                          },);
                      }, 
                      child: const Icon(Icons.filter_list)),
                  )
                ],
              )
            )
            //Spacer(),
            //Icon(Icons.filter_list_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
  
  bool isFiltered(Session session) {
    if (filters.containsKey('hideFull') && filters['hideFull']){
      return session.seatsTaken == session.seatsAvailable;
    }
    return false; 
  }
}
