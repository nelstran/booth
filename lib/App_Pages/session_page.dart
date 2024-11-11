import 'package:Booth/Helper_Functions/filter_sessions.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/expanded_session_page.dart';
import 'package:Booth/App_Pages/filter_ui.dart';
import 'package:Booth/App_Pages/search_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:rainbow_color/rainbow_color.dart';
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

class _SessionPage extends State<SessionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Map filters = {};
  bool friendsOnly = false;
  List blockedList = [];
  List blockedFromList = [];

  @override
  void initState(){
    super.initState();
    widget.controller.friendsOnlyNotifier.addListener(setFriendsTab);
  }

  void setFriendsTab(){
    setState((){
      friendsOnly = widget.controller.friendsOnlyNotifier.value;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // List<Color> sessionColor = [
    //   Colors.red,
    //   Colors.orange,
    //   Colors.yellow,
    //   Colors.green
    // ];

    Rainbow sessionColor = Rainbow(
      spectrum: [
        Colors.green,
        Colors.yellow,
        Colors.orange,
        Colors.red
      ]
    );

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
              return StreamBuilder(
                stream: widget.controller.studentRef().child("friends").onValue,
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (s.hasError) {
                    return Center(child: Text('Error: ${s.error}'));
                  }
                  // Get list of friends when it updates
                  Map? friendsEntry = {};
                  if (s.hasData && s.data!.snapshot.value != null){
                    friendsEntry = s.data!.snapshot.value as Map;
                  }
                  // Remove the requests
                  friendsEntry.remove("requests");

                  List friendsList = friendsEntry.keys.toList();

              // Getting list of blocked users --------------------------------------------  
              return StreamBuilder(
                stream: widget.controller.studentRef().child("blocked_from").onValue,
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (s.hasError) {
                    return Center(child: Text('Error: ${s.error}'));
                  }
                  // Get list of blocked from users when it updates
                  Map? blockedFromEntry = {};
                  if (s.hasData && s.data!.snapshot.value != null){
                    blockedFromEntry = s.data!.snapshot.value as Map;
                  }
                  blockedFromList = blockedFromEntry.keys.toList();
              
              return StreamBuilder(
                stream: widget.controller.studentRef().child("blocked").onValue,
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (s.hasError) {
                    return Center(child: Text('Error: ${s.error}'));
                  }
                  // Get list of blocked users when it updates
                  Map? blockedEntry = {};
                  if (s.hasData && s.data!.snapshot.value != null){
                    blockedEntry = s.data!.snapshot.value as Map;
                  }
                  blockedList = blockedEntry.keys.toList();
                // --------------------------------------------------------------------------
                  return FirebaseAnimatedList(
                    key: Key(institution),
                    query: widget.controller.sessionRef,
                    sort:(a, b) {
                      if (a.key == widget.controller.student.session){
                        return -1;
                      }
                      if (b.key == widget.controller.student.session){
                        return 1;
                      }
                      return 0;
                    },
                    // Build each item in the list view
                    itemBuilder: (BuildContext context, DataSnapshot snapshot,
                        Animation<double> animation, int index) {
                          try{
                            // Convert the snapshot to a Map
                            Map<dynamic, dynamic> json =
                                snapshot.value as Map<dynamic, dynamic>;
                  
                            // Here to avoid exception while debugging
                            if (!json.containsKey("users")){
                              return const SizedBox.shrink();
                            }
                  
                            Session session = Session.fromJson(json);
                            // Control the max number of users to display on the front page
                            int numOfPFPs = 4;
                            bool isInSession = widget.controller.student.session == snapshot.key!;
                            bool isFriends = isFriendsWithHost(json, friendsList);
                            bool isBlocked = isBlockedUserinSession(json, blockedList);

                            // Always show the session the user is in, otherwise check if session should be visible to user
                            if (!isInSession && (isFiltered(filters, session) || isNotViewable(json, isFriends) || isBlocked)) {
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
                  
                            // int colorIndex =
                            //     ((session.seatsTaken / session.seatsAvailable) * 100)
                            //         .floor();
                            Color fullness;
                            fullness = sessionColor[session.seatsTaken / session.seatsAvailable];
                            // if (colorIndex <= 33) {
                            //   fullness = sessionColor[3];
                            // } else if (colorIndex <= 66) {
                            //   fullness = sessionColor[2];
                            // } else if (colorIndex <= 99) {
                            //   fullness = sessionColor[1];
                            // } else {
                            //   fullness = sessionColor[0];
                            // }
                            return Column(
                              children: [
                                if (isInSession) const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text("My session")),
                                      Expanded(child: Divider())
                                    ],
                                  ),
                                ) else const SizedBox.shrink(),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                    elevation: 2,
                                    child: ClipPath(
                                      clipper: ShapeBorderClipper(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)
                                            )
                                          ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: fullness,
                                                width: 10,
                                              )
                                            )
                                        ),
                                        child: ListTile(
                                          // Display title and description
                                          title: Text(
                                            title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            // Show list and the people in that session represented by their pfp
                                            children: [
                                              Text(session.locationDescription),
                                              const SizedBox(height: 2),
                                              rowOfPFPs(memberNames, numOfPFPs, memberUIDs)
                                            ],
                                          ),
                                          trailing: Text(
                                            "[ ${session.seatsTaken} / ${session.seatsAvailable} ]",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 14)
                                          ),
                                          // trailing: SizedBox(
                                          //   height: 50,
                                          //   child: Column(
                                          //     crossAxisAlignment: CrossAxisAlignment.center,
                                          //     mainAxisAlignment: MainAxisAlignment.center,
                                          //     children: [
                                          //       if (isFriends) const Icon(Icons.people, color: Colors.green),
                                          //       Text(
                                          //           "[ ${session.seatsTaken} / ${session.seatsAvailable} ]",
                                          //           textAlign: TextAlign.center,
                                          //           style: const TextStyle(fontSize: 14)),
                                          //     ],
                                          //   ),
                                          // ),
                                          onTap: () {
                                            // Expand session
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => ExpandedSessionPage(
                                                    snapshot.key!, widget.controller),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isInSession) Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: !friendsOnly ? 
                                        Text('${widget.controller.studentInstitution} sessions')
                                        : const Text('Friends\' sessions'),
                                      ),
                                      const Expanded(child: Divider())
                                    ],
                                  ),
                                ) else const SizedBox.shrink()
                              ],
                            );
                          } catch (e){
                            // Skip
                            return const SizedBox.shrink();
                          }
                    },
                  );
                }
                );
                }
              );
            }
           );
          }
         ),
        ),
      ],
    );
  }

  SizedBox rowOfPFPs(
      List<String> memberNames, int numOfPFPs, List<String> memberUIDs) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount:
            memberNames.length > numOfPFPs ? numOfPFPs : memberNames.length,
        itemBuilder: (context, index) {
          var pfpRadius = 15.0;
          var pfpFontSize = 13.0;
          return Row(
            children: [
              StreamBuilder(
                stream: widget.controller.pfpRef(memberUIDs[index]).snapshots(),
                builder: (context, snapshot) {
                  return FutureBuilder(
                    future: widget.controller
                        .getProfilePictureByUID(memberUIDs[index], true),
                    builder: (context, snapshot) {
                      return Padding(
                        padding: const EdgeInsets.all(3.0),
                        // child: ProfilePicture(
                        //   name: memberNames[index],
                        //   radius: pfpRadius,
                        //   fontsize: pfpFontSize,
                        //   img: snapshot.data,
                        // ),
                        child: CachedProfilePicture(
                          name: memberNames[index],
                          radius: pfpRadius, 
                          fontSize: pfpFontSize,
                          imageUrl: snapshot.data
                        )
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
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const SizedBox.shrink()
            ],
          );
        },
      ),
    );
  }

  Widget boothSearchBar(BuildContext context) {
    return Container(
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
          Expanded(
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  await showSearch(
                    context: context,
                    delegate: SearchPage(controller: widget.controller),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 8.0),
                      Text(
                        'Search...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )),
          ),
          GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                showModalBottomSheet(
                        showDragHandle: true,
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return Wrap(children: [FilterUI(filters)]);
                        })
                    // After users apply filters, values will show up here
                    .then(
                  (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      filters.clear();
                      filters.addAll(value);
                    });
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 40,
                  width: 100,
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 22, 22, 22),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.filter_list)),
                ),
              ))
        ],
      ),
    );
  }
  
  /// Method to determine if the given session should be visible,
  /// only show private sessions to friends
  bool isNotViewable(Map<dynamic, dynamic> json, bool isFriends) {
    if(friendsOnly || !json['isPublic']){
      return !isFriends;
    }
    return false;
  }

  /// Method to check if user is friends with the host
  bool isFriendsWithHost(Map<dynamic, dynamic> json, List friendsList){
    if(json['ownerKey'] != ''){
      try{
        Map ownerEntry = json['users'][json['ownerKey']];
        if (ownerEntry.containsKey('key')){
          if (friendsList.contains(ownerEntry['key'])){
            return true;
          }
        }
      }
      catch (e){
        return false;
      }
    }
    return false;
  }

  /// Method to hide sessions that contain blocked users
  bool isBlockedUserinSession(Map<dynamic, dynamic> json, List blockedList){
    // Look at all students in a session
    List usersInSession = json['users'].values.toList();
    for(var i = 0; i < usersInSession.length; i++){
      // If a student in a session is blocked, hide that session
      if (blockedList.contains(usersInSession[i]['key'])){
        return true;
      }
      
      // If the student who has blocked the blocked user is in a session,
      // hide that session from the blocked user 
      if(blockedFromList.contains(usersInSession[i]['key'])){
        return true;
      }
    }
    return false;
  }

}
