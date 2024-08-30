import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/App_Pages/expanded_session_page.dart';
import 'package:flutter_application_1/App_Pages/display_profile_page.dart';
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
            return const Center(
              child: CircularProgressIndicator()
            );
          }
        });
  }

  Scaffold createUI() {
    // SUPER INSECURE DELETE WHEN DONE
    // TODO: (For testing) Delete
    var adminMode = controller.student.uid == 'MkqlxL5l30WnuiTKM3O7bpmbxGx1';

    List<AppBar> appBars = [
      mainAppBar(), // Session
      mainAppBar(), // Map
      mainAppBar(), // Usage
      profileAppBar(), // Profile
    ];
    var profilePage = ProfileDisplayPage(user: widget.user!, controller: controller);
    var sessionPage = SessionDestination(ref: _ref, controller: controller);
    List<Widget> pages = [
      sessionPage,
      const MapDestination(),
      const UsageDestination(),
      profilePage,
    ];
    List<Widget> destinations = [
          const NavigationDestination(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          const NavigationDestination(
            icon: Icon(Icons.map),
            label: "Map",
          ),
          const NavigationDestination(
            icon: Icon(Icons.data_thresholding),
            label: "Usage",
          ),
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ];

    // TODO: (For testing) Delete
    if (adminMode){
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
      floatingActionButton: currPageIndex == 0 ? FloatingActionButton(
        onPressed: () {
          // Navigate to the create session page
          Navigator.pushNamed(context, '/create_session',
              arguments: {'user': controller.student});
        },
        child: const Icon(Icons.add),
      ) : const SizedBox.shrink(),

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
      backgroundColor: Colors.blue,
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
          backgroundColor: Colors.blue,
          actions: [
            // Edit Button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final value = await Navigator.pushNamed(
                  context,
                  '/create_profile',
                  arguments: {"user" : widget.user, "controller": controller},
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
          content: const Text(
              '''Are you sure you want to delete your account? 

This action is permanent and cannot be undone. All your data, settings, and history will be permanently deleted. 
              
If you proceed, you will lose access to your account and all associated content.'''),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
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
                await deleteUserAccountFB(context);

                // Deletes the user from everywhere on our app
                deleteUserAccountEverywhere(controller);
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
      backgroundColor: Colors.blue,
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
            if (index == 0) boothSearchBar(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 3,
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
          ],
        );
      },
    );
  }

  SearchBar boothSearchBar(){
    return SearchBar(
      onSubmitted: (value) {
        // Do search things
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
            backgroundColor: WidgetStateColor.transparent
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

class MapDestination extends StatelessWidget{
  const MapDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Map Placeholder");
  }
}

class UsageDestination extends StatelessWidget{
  const UsageDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Usage Placeholder");
  }
}

class AdminDestination extends StatelessWidget{
  const AdminDestination({
    super.key,
    required DatabaseReference ref,
    required this.controller,
  }): _ref = ref;

  final DatabaseReference _ref;
  final BoothController controller;
  @override
  Widget build(BuildContext context) {
    List<String> myFriends = controller.getFriends();
    List<String> myRequests = controller.getRequests();
    return Column(
      children: [
        const Expanded(
          child: Text("Place backend stuff here to test")
        ),
        // Testing friend system
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text("Friends"),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: myFriends.length,
                        itemBuilder: (context, index){
                          return Text(myFriends[index]);
                        }
                      ),
                    )
                  ],
                ),
              ),
              VerticalDivider(),
              Expanded(
                child: Column(
                  children: [
                    const Text("Requests"),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: myRequests.length,
                        itemBuilder: (context, index){
                          return null;
                        }
                      ),
                    )
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

/// THIS SHOULD EVENTUALLY GO IN THE PROFILE PAGE
/// Deletes the user everywhere in our app;
/// - Any Sessions they are apart of
/// - Any Sessions that they currently own
/// - The list of users that are recorded in the DB
void deleteUserAccountEverywhere(BoothController controller) {
  // First Check to see if the user is apart of any study sessions
  // If so, remove from study session
  if (controller.student.session != "") {
    controller.removeUserFromSession(
        controller.student.session, controller.student.sessionKey);
  }
  // Check is their are any sessions that they OWN and remove the session
  if (controller.student.ownedSessionKey != "") {
    controller.removeUserFromSession(
        controller.student.session, controller.student.sessionKey);
    controller.removeSession(controller.student.ownedSessionKey);
  }
  // Then, remove from the "users" list in the Database
  controller.removeUser(controller.student.key);
}
