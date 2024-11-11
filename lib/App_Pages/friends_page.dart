import 'package:Booth/App_Pages/expanded_session_page.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/App_Pages/requests_page.dart';
import 'package:Booth/MVC/friend_extension.dart';
import 'package:Booth/MVC/profile_extension.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage(this.controller, {super.key});
  final BoothController controller;

  @override
  State<StatefulWidget> createState() => _FriendsPage();
}

class _FriendsPage extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    Future<Map<dynamic, dynamic>> requests =
        widget.controller.getRequests(false);
    Future<Map<dynamic, dynamic>> friends = widget.controller.getFriends();
    var requestsList = {};
    var friendsList = {};
    return Scaffold(
        appBar: AppBar(
          title: const Text('Friends List'),
        ),
        body: FutureBuilder(
        future: Future.wait([requests, friends]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          requestsList = snapshot.data![0];
          friendsList = snapshot.data![1];

          double pfpRadius = 25;
          double pfpFontSize = 20;

          return Column(
            children: [
              // Requests header
              if (snapshot.data![0].isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    // Navigate to the RequestsPage
                    await Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) =>
                            RequestsPage(widget.controller),
                      ),
                    );
                    setState(() {
                      requests = widget.controller.getRequests(false);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Requests (${requestsList.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right),
                      ],
                    ),
                  ),
                ),
              // Friends header
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Friends",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (snapshot.data![1].isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: friendsList.length,
                    itemBuilder: (context, index) {
                      final userKey = friendsList.keys.elementAt(index);
                      final userName = friendsList[userKey] as String;
                      return friendTile(userKey, userName, pfpRadius, pfpFontSize);
                    }
                  ),
                )
              else
                const Center(child: Text('No friends found'))
            ],
          );
        }
      )
    );
  }

  StreamBuilder<DatabaseEvent> friendTile(userKey, String userName, double pfpRadius, double pfpFontSize) {
    return StreamBuilder(
      stream: widget.controller
        .studentRef(userKey)
        .onValue,
      builder: (context, snapshot) {
        bool isOnline = false;
        bool inASession = false;
        String sessionKey = '';
        if (snapshot.hasData && snapshot.data!.snapshot.value != null){
          Map json = snapshot.data!.snapshot.value as Map;
          try{
            isOnline = json['onlineStatus']['isOnline'];
          }
          catch (e) {
            // Do nothing if user does not have online status in database
          }

          try {
            sessionKey = json['session'];
            inASession = sessionKey.isNotEmpty;
          }
          catch (e) {
            // User does not have session tag in database
          }
        }
        String status = 'Offline';
        if (inASession){
          status = 'In a study session';
        }
        else {
          status = isOnline ? "Active" : "Offline";
        }

        return Dismissible(
          // Dismissible allows swipe away actions
          key: Key(userKey),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            child: const Padding(
              padding: EdgeInsets.only(right: 32.0),
              child: Icon(
                Icons.person_remove,
                color: Colors.white
              ),
            ),
          ),
          background: Container(
            alignment: Alignment.centerLeft,
            color: Colors.blue,
            child: const Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: Icon(
                Icons.subdirectory_arrow_left,
                color: Colors.white
              ),
            ),
          ),
          // Unlock swipe right to navigate to friend's session
          direction: inASession ? DismissDirection.horizontal : DismissDirection.endToStart,
          confirmDismiss: (direction) {
            if (direction == DismissDirection.startToEnd){
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ExpandedSessionPage(sessionKey, widget.controller),
                ),
              );
              return Future.value(false);
            }
            if (direction == DismissDirection.endToStart){
              return showConfirmationDialog(context, userName, userKey);
            }
            return Future.value(false);
          },
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: profilePicture(userKey, userName, pfpRadius, pfpFontSize),
              title: Text(
                userName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Text(status),
                ],
              ),
              trailing: friendOptions(inASession, context, userName, userKey, sessionKey),
              onTap: () {
                // Navigate to the profile page of the selected friend
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDisplayPage(
                        widget.controller, userKey, false),
                  ),
                );
              },
            )
          )
        );
      }
    );
  }

  PopupMenuButton<int> friendOptions(bool inASession, BuildContext context, String userName, userKey, String sessionKey) {
    return PopupMenuButton<int>(
                                //  Popup menu for options (currently remove friend option)
                                icon: const Icon(Icons.more_vert),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 1,
                                    child: Text('Remove Friend'),
                                  ),
                                  if (inASession) const PopupMenuItem(
                                    value: 2,
                                    child: Text('Go to session')
                                  )
                                ],
                                onSelected: (value) {
                                  if (value == 1) {
                                    showConfirmationDialog(
                                        context, userName, userKey);
                                  }
                                  if (value == 2){
                                    // Navigate to friend's session if they are in one
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExpandedSessionPage(sessionKey, widget.controller),
                                      ),
                                    );
                                  }
                                },
                              );
  }

  StreamBuilder<DocumentSnapshot<Object?>> profilePicture(userKey, String userName, double pfpRadius, double pfpFontSize) {
    return StreamBuilder(
                                  stream: widget.controller
                                      .pfpRef(userKey)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    return FutureBuilder(
                                      future: widget.controller
                                          .getProfilePictureByKey(userKey, true),
                                      builder: (context, snapshot) {
                                        return Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: CachedProfilePicture(
                                            name: userName,
                                            imageUrl: snapshot.data,
                                            radius: pfpRadius,
                                            fontSize: pfpFontSize,
                                          ),
                                        );
                                      },
                                    );
                                  });
  }

  Future<bool> showConfirmationDialog(
      BuildContext context, String userName, String userId) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: Text('Are you sure you want to unfriend $userName ?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                widget.controller.removeFriend(userId);
                Navigator.pop(context);
                // Show snackbar for confirmation (optional)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed $userName from friends'),
                  ),
                );
                confirm = true;
              },
            ),
          ],
        );
      },
    );
    return confirm;
  }
}
