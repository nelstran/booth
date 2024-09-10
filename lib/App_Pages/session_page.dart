import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/App_Pages/expanded_session_page.dart';
import 'package:flutter_application_1/App_Pages/display_profile_page.dart';
import 'package:flutter_application_1/App_Pages/search_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import '../MVC/session_model.dart';

/// This is the home page - where Booth Sessions appear in list view
class SessionPage extends StatefulWidget {
  final User? user;

  const SessionPage(this.user, {super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  // Reference to the Firebase Database sessions node
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  late final BoothController controller = BoothController(_ref);
  int currPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get user profile before loading everything
    return FutureBuilder(
        future: controller.fetchAccountInfo(widget.user!),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return createUI();
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Scaffold createUI() {
    // SUPER INSECURE DELETE WHEN DONE
    // TODO: (For testing) Delete
    List<String> admins = [
      'niiLt2Sf5OTakdnuAqpMVBgrmZV2', // Booth Admin
      'wUxLN0owVqZGEIBeMOt9q6lVBzL2', // Booth Admin 2
    ];
    var adminMode = admins.contains(controller.student.uid);

    List<AppBar> appBars = [
      mainAppBar(), // Session
      mainAppBar(), // Map
      mainAppBar(), // Usage
      profileAppBar(), // Profile
    ];
    var profilePage = ProfileDisplayPage(widget.user!, controller);
    var sessionPage = SessionDestination(ref: _ref, controller: controller);
    List<Widget> pages = [
      sessionPage,
      const MapDestination(),
      const UsageDestination(),
      profilePage,
    ];
    List<Widget> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home, color: Colors.white),
        label: "Home",
      ),
      const NavigationDestination(
        icon: Icon(Icons.map, color: Colors.white),
        label: "Map",
      ),
      const NavigationDestination(
        icon: Icon(Icons.data_thresholding, color: Colors.white),
        label: "Usage",
      ),
      const NavigationDestination(
        icon: Icon(Icons.person, color: Colors.white),
        label: "Profile",
      ),
    ];

    // TODO: (For testing) Delete
    if (adminMode) {
      appBars.add(adminAppBar());
      pages.add(AdminDestination(ref: _ref, controller: controller));
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.settings),
        label: "Admin",
      ));
    }

    return Scaffold(
      appBar: appBars[currPageIndex],
      // Body
      body: pages[currPageIndex],
      // Floating Action Button
      floatingActionButton: currPageIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to the create session page
                Navigator.pushNamed(context, '/create_session',
                    arguments: {'user': controller.student});
              },
              child: const Text("Create Session"),
            )
          : const SizedBox.shrink(),
      // Testing the difference between BottomNavigationBar and NavigationBar -- Nelson
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int i) {
          setState(() {
            currPageIndex = i;
          });
        },
        selectedIndex: currPageIndex,
        destinations: destinations,
      ),
    );
  }

  AppBar mainAppBar() {
    return AppBar(
      title: Text("Booth | Welcome ${controller.student.fullname}!"),
      actions: const [
        // This button is linked to the logout method
        IconButton(
          onPressed: logout,
          icon: Icon(Icons.logout),
        ),
      ],
    );
  }

  AppBar profileAppBar() {
    return AppBar(
      title: const Text('Profile'),
      actions: [
        // Edit Button
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final value = await Navigator.pushNamed(
              context,
              '/create_profile',
              arguments: {"user": widget.user, "controller": controller},
            );
            // Causes the page to update when user is done
            setState(() {
              currPageIndex = currPageIndex;
            });
          },
        ),
        // Delete Button
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            deletionDialog();
          },
        ),
      ],
    );
  }

  Future<dynamic> deletionDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Account Deletion"),
          content: const Text('''Are you sure you want to delete your account? 

This action is permanent and cannot be undone. All your data, settings, and history will be permanently deleted. 
              
If you proceed, you will lose access to your account and all associated content.'''),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                // Deletes the account from FireBase (In Controller)
                // Await is used so that the user is deleted on FB Auth before the app
                // tries to delete the user from our realtime database
                await controller.deleteUserAccountFB(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                "Delete My Account",
              ),
            ),
          ],
        );
      },
    );
  }

  AppBar adminAppBar() {
    return AppBar(
      title: Text("Admin Page"),
      actions: const [
        // This button is linked to the logout method
        IconButton(
          onPressed: logout,
          icon: Icon(Icons.logout),
        ),
      ],
    );
  }
}

class SessionDestination extends StatelessWidget {
  const SessionDestination({
    super.key,
    required DatabaseReference ref,
    required this.controller,
  }) : _ref = ref;

  final DatabaseReference _ref;
  final BoothController controller;

  @override
  Widget build(BuildContext context) {
    List<Color> sessionColor = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green
    ];

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
        return Column(
          children: [
            if (index == 0) boothSearchBar(context),
            Padding(
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
              ),
            ),
          ],
        );
      },
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

class MapDestination extends StatelessWidget {
  const MapDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Map Placeholder");
  }
}

class UsageDestination extends StatelessWidget {
  const UsageDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Usage Placeholder");
  }
}

class AdminDestination extends StatelessWidget {
  const AdminDestination({
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
            flex: 1, child: Text("Place backend stuff here to test")),
        // Testing friend system
        const Divider(),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text("All users"),
                    const Divider(),
                    Expanded(
                        flex: 1,
                        child: FirebaseAnimatedList(
                          query: _ref.child("users"),
                          itemBuilder: (BuildContext context,
                              DataSnapshot snapshot,
                              Animation<double> animation,
                              int index) {
                            Map<dynamic, dynamic> json =
                                snapshot.value as Map<dynamic, dynamic>;
                            if (json['uid'] == controller.student.uid)
                              return const SizedBox.shrink();
                            return ListTile(
                              title: Text(
                                json["name"],
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(Icons.add),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                controller.sendFriendRequest(snapshot.key!);
                              },
                            );
                          },
                        )),
                  ],
                ),
              ),
              const VerticalDivider(),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const Text("Friends"),
                    const Divider(),
                    Expanded(
                        child: FutureBuilder(
                      future: controller.getFriends(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        if (snapshot.data!.isEmpty)
                          return const SizedBox.shrink();
                        Map<dynamic, dynamic> friends =
                            snapshot.data as Map<dynamic, dynamic>;
                        List<dynamic> friendKeys = friends.keys.toList();
                        return ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(friends[friendKeys[index]]),
                                contentPadding: const EdgeInsets.all(0),
                                trailing: ElevatedButton(
                                  child: const Icon(Icons.remove),
                                  onPressed: () {
                                    controller.removeFriend(friendKeys[index]);
                                  },
                                ),
                              );
                            });
                      },
                    ))
                  ],
                ),
              ),
              const VerticalDivider(),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                        child: Column(
                      children: [
                        const Text("Incoming Requests"),
                        const Divider(),
                        Expanded(
                            child: FutureBuilder(
                          future: controller.getRequests(false),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            Map<dynamic, dynamic> json =
                                snapshot.data as Map<dynamic, dynamic>;
                            if (json.isEmpty) return const SizedBox.shrink();
                            var keys = json.keys.toList();
                            return ListView.builder(
                              itemCount: json.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(json[keys[index]]),
                                  trailing: Column(
                                    children: [
                                      GestureDetector(
                                        child: const Icon(Icons.check),
                                        onTap: () {
                                          controller
                                              .acceptFriendRequest(keys[index]);
                                        },
                                      ),
                                      GestureDetector(
                                        child: const Icon(Icons.close),
                                        onTap: () {
                                          controller.declineFriendRequest(
                                              keys[index]);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        )),
                      ],
                    )),
                    Expanded(
                        child: Column(
                      children: [
                        const Text("Outgoing Requests"),
                        const Divider(),
                        Expanded(
                            child: FutureBuilder(
                          future: controller.getRequests(true),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            Map<dynamic, dynamic> json =
                                snapshot.data as Map<dynamic, dynamic>;
                            if (json.isEmpty) return const SizedBox.shrink();
                            var keys = json.keys.toList();
                            return ListView.builder(
                              itemCount: json.length,
                              itemBuilder: (context, index) {
                                return Text(keys[index]);
                              },
                            );
                          },
                        )),
                      ],
                    )),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

/// *********  HELPER METHODS  *****************
// This method logs the user out
void logout() {
  FirebaseAuth.instance.signOut();
}
