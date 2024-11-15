import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/block_extension.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage(this.controller, {super.key});
  final BoothController controller;

  @override
  State<StatefulWidget> createState() => _BlockedUsersPage();
}

class _BlockedUsersPage extends State<BlockedUsersPage> {
  @override
  Widget build(BuildContext context) {
    Future<Map<dynamic, dynamic>> blockedUsers = widget.controller.getBlockedUsersName(widget.controller.student.key);
    var blockedUsersList = {};
    return Scaffold(
        appBar: AppBar(
          title: const Text('Blocked Users List'),
        ),
        body: FutureBuilder(
        future: blockedUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          blockedUsersList = snapshot.data!;

          double pfpRadius = 25;
          double pfpFontSize = 20;

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Blocked Users",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (blockedUsersList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: blockedUsersList.length,
                    itemBuilder: (context, index) {
                      final userKey = blockedUsersList.keys.elementAt(index);
                      final userName = blockedUsersList[userKey] as String;
                      return blockedUserTile(userKey, userName, pfpRadius, pfpFontSize);
                    }
                  ),
                )
              else
                const Center(child: Text('No blocked users found'))
            ],
          );
        }
      )
    );
  }

  StreamBuilder<DatabaseEvent> blockedUserTile(userKey, String userName, double pfpRadius, double pfpFontSize) {
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

        return 
          ListTile(
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
              trailing: unblockButton(context, userName, userKey),
              onTap: () {
                // Navigate to the profile page of the selected user
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDisplayPage(
                        widget.controller, userKey, false),
                  ),
                );
              },
            );
        }
      );
  }

  ElevatedButton unblockButton(BuildContext context, String userName, userKey) {
    return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
          shape: StadiumBorder(),
          ),
          onPressed: () {
            showConfirmationDialog(
            context, userName, userKey);
          },
          label: const Text("Unblock"),
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
          title: const Text('Confirm Unblock'),
          content: Text('Are you sure you want to unblock $userName ?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Unblock'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                widget.controller.unblockUser(userId);
                Navigator.pop(context);
                // Show snackbar for confirmation (optional)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed $userName from blocked users'),
                  ),
                );
                setState(() {});
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
