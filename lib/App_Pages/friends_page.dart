import 'package:Booth/UI_components/cached_profile_picture.dart';
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
                  if (snapshot.data![0].isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        // Navigate to the RequestsPage
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
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
                            const Text(
                              "Requests",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                                "(${requestsList.length})"), // Show # of requests
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

                            return Dismissible(
                              // Dismissible allows swipe away actions
                              key: Key(userKey),
                              background: Container(
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              // onDismissed: (direction) {
                              //   if (direction == DismissDirection.endToStart) {
                              //     showConfirmationDialog(context, userName, userId);
                              //   }
                              // },
                              confirmDismiss: (direction) {
                                return showConfirmationDialog(
                                    context, userName, userKey);
                              },
                              child: Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: ListTile(
                                  leading: StreamBuilder(
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
                                      }),
                                  title: Text(
                                    userName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      getStatusIndicator(userKey),
                                      const SizedBox(width: 8),
                                      Text(getAvailability(userKey)),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<int>(
                                    //  Popup menu for options (currently remove friend option)
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 1,
                                        child: Text('Remove Friend'),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 1) {
                                        showConfirmationDialog(
                                            context, userName, userKey);
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    // Navigate to the profile page of the selected friend
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserDisplayPage(
                                            widget.controller, userKey, false),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                    )
                  else
                    const Center(child: Text('No friends found'))
                ],
              );
            }));
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

  // TODO: Function to return availability, replace with actual logic
  String getAvailability(String userId) {
    return "Online";
  }

  // Widget for availability status indicator
  Widget getStatusIndicator(String userId) {
    final availability = getAvailability(userId);
    Color dotColor;

    switch (availability) {
      case "Online":
        dotColor = Colors.green;
        break;
      case "Away":
        dotColor = Colors.yellow;
        break;
      default:
        dotColor = Colors.grey;
        break;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
