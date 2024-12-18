import 'package:Booth/App_Pages/blocked_users_page.dart';
import 'package:Booth/App_Pages/create_session_page.dart';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/MVC/analytics_extension.dart';
import 'package:Booth/MVC/block_extension.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/saved_sessions_extension.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/session_model.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:Booth/UI_components/focus_image.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

/// Page to show more details about the selected session
/// and allow the user to join and leave the session as
/// well as delete/archive the session if the user owns it
class SessionDetailsPage extends StatefulWidget{
  final BoothController controller;
  final String sessionKey;
  final PageController pg;
  const SessionDetailsPage(this.sessionKey, this.controller, this.pg, {super.key});

  @override
  State<StatefulWidget> createState() => _SessionDetailsPage();
}

class _SessionDetailsPage extends State<SessionDetailsPage> {
  late BoothController controller = widget.controller;
  late bool isInThisSession;
  late bool isOwner;
  late Color buttonColor;
  bool showingSnack = false;
  var lock = Lock();

  @override
  void initState(){
    super.initState();
    isInThisSession = controller.student.session == widget.sessionKey;
    isOwner = controller.student.ownedSessionKey == widget.sessionKey;
    updateState();
  }
  updateState() {
    buttonColor = (isInThisSession ? Colors.red[900] : Colors.green[800])!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Booth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum),
            onPressed: () {
              widget.pg.animateToPage(
                1, 
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut
              );
            },
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Navigate to Edit Session Page
                if (!context.mounted) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateSessionPage(widget.controller,
                          sessionKey: widget.sessionKey),
                    ));
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Update when session changes
        child: StreamBuilder(
          stream: controller.sessionRef.child(widget.sessionKey).onValue,
          builder: (context, snapshot) {
            // Update when blocking users
            return StreamBuilder(
              stream: controller.studentRef().child("blocked").onValue,
              builder: (context, blockedSnaps) {
                // Update when getting blocked
                return StreamBuilder(
                  stream: controller.studentRef().child("blocked_from").onValue,
                  builder: (context, fromSnaps) {
                    return FutureBuilder(
                      future: Future.wait([
                        widget.controller.getBlockedUsers(widget.controller.student.key),
                        widget.controller.getBlockedFromUsers(widget.controller.student.key)
                      ]),
                      builder: (context, listSnapshot) {
                        var blockedUsersList = [];
                        if(listSnapshot.hasData){
                          blockedUsersList = listSnapshot.data![0].keys.toList();
                          blockedUsersList.addAll(listSnapshot.data![1].keys.toList());
                        }
                        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      Map<dynamic, dynamic> json =
                          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      try{
                        Session session = Session.fromJson(json);
                        Map users = json['users'];
                        try{
                          if(blockedUsersList.isNotEmpty){
                            for (String userKey in users.keys){
                              String key = users[userKey]["key"];
                              if (blockedUsersList.contains(key)){
                                return const Center(
                                  child: Text(
                                    "This session has been hidden",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold
                                    )
                                  )
                                );
                              }
                            }
                          }
                        }
                        catch(e){
                          // Skip if user has no key, (most likely dummy data)
                        }
                        List<String> memberNames = json["users"]
                            .values
                            .map<String>((value) => value['name'] as String)
                            .toList();
                
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Details of session
                            sessionDetails(session, context),
                            // List of students in the session
                            sessionLobby(memberNames, json),
                            // Button to join and leave the session
                            Expanded(
                                flex: 1,
                                child: joinLeaveButton(snapshot.data!.snapshot.key!, session)
                                ),
                          ],
                        );
                      } catch(e){
                        return const Center(
                          child: Text(
                            "There is a problem with this session",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                            )
                          )
                        );
                      }              
                    } else if (snapshot.hasData && !snapshot.data!.snapshot.exists){
                      return const Center(
                        child: Text(
                          "This session no longer exists",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                          )
                        )
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                      }
                    );
                  },
                );
              }
            );
          }
        ),
      ),
    );
  }

  Expanded sessionLobby(List<String> memberNames, Map<dynamic, dynamic> json) {
    List<String> memberUIDs = [];
    List<String> memberKeys = [];
    Map<String, dynamic> usersInFS =
        Map<String, dynamic>.from(json['users']);
    usersInFS.forEach((key, value) {
      memberUIDs.add(value['uid']);
      if ((value as Map).containsKey('key')){
        memberKeys.add(value['key']);
    }
    else{
        memberKeys.add("");
    }
    });
    return Expanded(
    flex: 3,
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Students in Session:',
            style: TextStyle(
                fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          // Display a list of users in the session along with their pfp and the ability to click on their profile
          Expanded(
            child: ListView.builder(
              itemCount: memberNames.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (memberKeys[index].isEmpty){
                      displaySnackbar("Cannot find ${memberNames[index]}'s profile!");
                      return;
                    }
                    if (showingSnack) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                    // Navigate to the profile page of the selected friend
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserDisplayPage(
                            widget.controller, memberKeys[index], false, false),
                      ),
                    );
                  },
                  child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          StreamBuilder(
                            stream: controller
                                .pfpRef(memberUIDs[index])
                                .snapshots(),
                            builder: (context, snapshot) {
                              return FutureBuilder(
                                future: widget.controller.getProfilePictureByUID(memberUIDs[index], true),
                                builder: (context, snapshot) {
                                  return CachedProfilePicture(
                                    name: memberNames[index],
                                    imageUrl: snapshot.data,
                                    radius: 15, 
                                    fontSize: 13
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            memberNames[index],
                            style:
                                const TextStyle(fontSize: 16.0),
                          ),
                        ],
                      )),
                );
              },
            ),
          ),
        ]
      )
    );
  }

  Expanded sessionDetails(Session session, BuildContext context) {
    return Expanded(
      flex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            session.title,
            style: const TextStyle(
                fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          Text(
            'Description: ${session.description}',
            style: const TextStyle(fontSize: 18.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Location Description: ${session.locationDescription}',
                  style: const TextStyle(fontSize: 18.0),
                ),
              ),
              if (session.imageURL != null) GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:() {
                  // Display the location image on the screen for users to see where 
                  // the owner is. We modified existing values to make the experience instant
                  Navigator.of(context).push(PageRouteBuilder(
                    opaque: false,
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (context, _, __) =>
                      FocusImage(session.imageURL!, imageDesc: session.locationDescription)
                  ));
                },
                child: const Padding(
                  padding: EdgeInsets.only(left:8.0, top: 8, bottom:8),
                  child: Row(
                    children: [
                      Icon(Icons.image),
                      Icon(Icons.arrow_forward_ios)
                    ],
                  ),
                )
              )
            ],
          ),
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
          Row(
            children: [
              const Icon(Icons.subject, size: 18.0),
              const SizedBox(width: 5.0),
              Text(
                'Class: ${session.subject}',
                style: const TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ]
      ),
    );
  }

  Padding joinLeaveButton(String key, Session session) {
    int seatsLeft = session.seatsAvailable - session.seatsTaken;
    String buttonText = isInThisSession ? "Leave" : "Join";
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: seatsLeft == 0 && !isInThisSession
            ? Colors.grey[800]
            : buttonColor,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: Center(
          child: seatsLeft == 0 && !isInThisSession
            ? const Text("Full")
            : TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size.fromWidth(double.infinity),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
              ),
              onPressed: lock.locked ? null : () => _handleOnButtonPress(session, key),
              child: Text(
                key == controller.student.ownedSessionKey
                ? "Disband"
                : buttonText
              ),
            )
        )
      ),
    );
  }

  /// Method to join/leave/delete the session when users click the button
  Future<void> _handleOnButtonPress (session, key) async {
    if (lock.locked){
      return;
    }

    // We add a lock to make sure everything is done and 
    // completed to prevent duplicate entries upon spamming the button
    await lock.synchronized(() async {
      // Delete/Archive owned session
      if (controller.student.ownedSessionKey != "") {
        if(controller.student.ownedSessionKey == key){
          bool? action = await _askToArchive();
          if (action == null){
            return;
          }
          else if (action){
            await widget.controller.saveSession(controller.student.uid, session);
            displaySnackbar("Session archived!");
          }
        }
        await _deleteOwnedSession(session, key);
      } 
      // Kicks user of old session when joining new one
      if (isInThisSession) {
        await controller.removeUserFromSession(
            widget.sessionKey, controller.student.sessionKey);
      } else {
        await controller.addUserToSession(
            widget.sessionKey, controller.student);
        controller.startSessionLogging(
            controller.student.uid, session);
      }
      if(!mounted) return;
      setState(() {
        isInThisSession =
            !isInThisSession; // Janky way to update state UI
        updateState();
      });
    });
  }

  /// Method to ask users if they would like to save their sessions to reuse later or delete it
  Future<bool?> _askToArchive() async {
    return await showDialog(
          context: context, 
          builder: (context){
            return AlertDialog(
          title: const Text(
            "Notice",
          ),
          content: const Text("Would you like to archive your session?"),
          actions:[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context, false);
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
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                    ),
                  child: const Text(
                    "Archive",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ],
            )
          ]
        );
      }
    );
  }

  /// Method to delete the session
  Future<void> _deleteOwnedSession(session, key) async {
    var sessionToDelete =
        controller.student.ownedSessionKey;
    if (key == sessionToDelete){
      Navigator.of(context).pop();
    }
    await controller.removeUserFromSession(
        controller.student.session,
        controller.student.sessionKey);
    await controller.removeSession(sessionToDelete);
  }

  /// Method to display a snackbar with the given [text]
  void displaySnackbar(String text) {
    if (showingSnack) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    showingSnack = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)))
        .closed
        .then((reason) {
      showingSnack = false;
    });
  }
}