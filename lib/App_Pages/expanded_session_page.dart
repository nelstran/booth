import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/create_session_page.dart';
import 'package:Booth/MVC/analytics_extension.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:synchronized/synchronized.dart';

import '../MVC/session_model.dart';

class ExpandedSessionPage extends StatefulWidget {
  final BoothController controller;
  final String sessionKey;
  const ExpandedSessionPage(this.sessionKey, this.controller, {super.key});
  

  @override
  State<ExpandedSessionPage> createState() {
    return _ExpandedSessionPageState();
  }
}

class _ExpandedSessionPageState extends State<ExpandedSessionPage> {
  late BoothController controller = widget.controller;
  late bool isInThisSession;
  late bool isOwner;
  late Color buttonColor;
  bool showingSnack = false;
  var lock = Lock();


  @override
  void initState() {
    super.initState();
    isInThisSession = controller.student.session == widget.sessionKey;
    isOwner = controller.student.ownedSessionKey == widget.sessionKey;
    updateState();
    // Log an event when the widget is initialized
  }

  updateState() {
    buttonColor = (isInThisSession ? Colors.red[900] : Colors.green[800])!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth'),
        actions: [
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
        child: StreamBuilder(
          stream: controller.sessionRef.child(widget.sessionKey).onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> json =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              // Here to avoid exception while debugging
              if (!json.containsKey("users")) return const SizedBox.shrink();

              Session session = Session.fromJson(json);
              List<String> memberNames = json["users"]
                  .values
                  .map<String>((value) => value['name'] as String)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details of session
                  Expanded(
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
                        // const SizedBox(height: 20.0),
                        Text(
                          'Description: ${session.description}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        // const SizedBox(height: 20.0),
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
                                Navigator.of(context).push(PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (context, _, __) =>
                                    LocationImageDialog(session)
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
                        // const SizedBox(height: 20.0),
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
                        // const SizedBox(height: 20.0),
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
                        // const SizedBox(height: 20.0),
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
                  ),
                  // List of students in the session
                  Expanded(
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
                            Expanded(
                              child: ListView.builder(
                                itemCount: memberNames.length,
                                itemBuilder: (context, index) {
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
                                  return GestureDetector(
                                    onTap: () {
                                      if (memberKeys[index].isEmpty){
                                        displayWarning("Cannot find ${memberNames[index]}'s profile!");
                                        return;
                                      }
                                      if (showingSnack) {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      }
                                      // Navigate to the profile page of the selected friend
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => UserDisplayPage(
                                              widget.controller, memberKeys[index], false),
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
                          ])),
                  // Button to join and leave the session
                  Expanded(
                      flex: 1,
                      child: joinLeaveButton(snapshot.data!.snapshot.key!,
                          session) // Extracted UI to method to keep things simple
                      ),
                ],
              );
            } else if (snapshot.hasData && !snapshot.data!.snapshot.exists){
              // Set text instead of automatically going back otherwise would confuse users
              return const Center(child: Text("This session no longer exists..."));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: lock.locked ? null : () async {
                        if (lock.locked){
                          return;
                        }
                        await lock.synchronized(() async {
                          // Delete owned session
                          if (controller.student.ownedSessionKey != "") {
                            var sessionToDelete =
                                controller.student.ownedSessionKey;
                            if (key == sessionToDelete){
                              Navigator.of(context).pop();
                            }
                            await controller.removeUserFromSession(
                                controller.student.session,
                                controller.student.sessionKey);
                            await controller.removeSession(sessionToDelete);
                            if (key == sessionToDelete){
                              return;
                            }
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
                          setState(() {
                            isInThisSession =
                                !isInThisSession; // Janky way to update state UI
                            updateState();
                          });
                        });
                      },
                    child: Text(
                      key == controller.student.ownedSessionKey
                      ? "Delete"
                      : buttonText
                    ),
                    ))),
    );
  }
  void displayWarning(String text) {
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

  void showPicture(Session session){
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context){
        return AlertDialog(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.locationDescription,
                // style: const TextStyle(fontSize: 30),
              ),
            ]
          ),
          titlePadding: const EdgeInsets.only(bottom: 8, top: 16, left: 16, right: 16),
          content: CachedNetworkImage(
            imageUrl: session.imageURL!,
            progressIndicatorBuilder: (context, url, progress) => 
              CircularProgressIndicator(value: progress.progress),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 24),
          actions:[
            ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  elevation: 0.0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                ),
              child: const Text(
                "Ok",
                style: TextStyle(color: Colors.white),
              ),
            )
          ]
        );
      }
    );
  }
}

class LocationImageDialog extends StatelessWidget {
  const LocationImageDialog(
    this.session,
    {super.key}
  );
  final Session session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.8),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    "Tap to dismiss",
                    style: TextStyle(
                      fontSize: 15
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          session.locationDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl: session.imageURL!,
                        progressIndicatorBuilder: (context, url, progress) => 
                          Center(
                            child: CircularProgressIndicator(value: progress.progress),
                          ),
                      )
                    ],
                  ))
              ],
            ),
          ),
        ),
      ),
    );
  }
  
}
