import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/App_Pages/admin_page.dart';
import 'package:flutter_application_1/App_Pages/display_profile_page.dart';
import 'package:flutter_application_1/App_Pages/map_page.dart';
import 'package:flutter_application_1/App_Pages/session_page.dart';
import 'package:flutter_application_1/App_Pages/usage_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class MainPage extends StatefulWidget {
  final User? user;

  const MainPage(this.user, {super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
    var sessionPage = SessionPage(ref: _ref, controller: controller);
    List<Widget> pages = [
      sessionPage,
      const MapPage(),
      const UsagePage(),
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
      pages.add(AdminPage(ref: _ref, controller: controller));
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
      actions: [
        // This button is linked to the logout method
        IconButton(
          onPressed: logout,
          icon: const Icon(
            Icons.logout,
            color: Colors.white,
          ),
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
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              onPressed: () async {
                await Navigator.pushNamed(
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
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: () {
                deletionDialog();
              },
            ),
          ],
        );
  }

  AppBar adminAppBar() {
    return AppBar(
      title: const Text("Admin Page"),
      backgroundColor: Colors.blue,
      actions: [
        // This button is linked to the logout method
        IconButton(
          onPressed: logout,
          icon: const Icon(
            Icons.logout,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// *********  HELPER METHODS  *****************
  // This method logs the user out
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  // This method asks if the user wants to delete their account
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
                controller.student.deleteUserAccountEverywhere(controller);
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
}