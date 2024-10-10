import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/admin_page.dart';
import 'package:flutter_application_1/App_Pages/create_profile_page.dart';
import 'package:flutter_application_1/App_Pages/create_session_page.dart';
import 'package:flutter_application_1/App_Pages/display_profile_page.dart';
import 'package:flutter_application_1/App_Pages/institutions_page.dart';
import 'package:flutter_application_1/App_Pages/map_page.dart';
import 'package:flutter_application_1/App_Pages/session_page.dart';
import 'package:flutter_application_1/App_Pages/settings_page.dart';
import 'package:flutter_application_1/App_Pages/usage_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/sample_extension.dart';

/// This is the home page - defaults to the session page
class MainUIPage extends StatefulWidget {
  final User? user;
  final bool isLoggingIn;

  const MainUIPage(
    this.user, 
    this.isLoggingIn,
    {super.key}
  );

  @override
  State<MainUIPage> createState() => _MainUIPageState();
}

class _MainUIPageState extends State<MainUIPage> {
  // Reference to the Firebase Database sessions node
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  late final BoothController controller = BoothController(_ref);
  int currPageIndex = 0;
  late PageController pageController;

  late List<AppBar> appBars = [];
  late List<Widget> pages = [];
  late List<Widget> destinations = [];

  @override
  Widget build(BuildContext context) {
    // Get user profile before loading everything
    return FutureBuilder(
      future: appSetup(widget.user),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return createUI();
        }
        else if (snapshot.hasError){
          return errorDialog();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }
    );
  }

  Future<String> appSetup(user) async {
    String data = await controller.fetchAccountInfo(user);
    String institution = controller.studentInstitution;
    // Make sure users are assigned an institution
    if (institution == "" && mounted){
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InstitutionsPage(controller, widget.isLoggingIn ? "Login" : "Register")
        )
      );
    }
    Map sessions = await controller.getInstitute(institution);
    if (sessions.isEmpty){
      // Create dummy data
      var numOfSessions = Random().nextInt(9) + 6;
      controller.createNSampleSessions(numOfSessions);
    }
    return data;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // accountSpecificSetup().then;
    controller.fetchAccountInfo(widget.user!).whenComplete(() {
      accountSpecificSetup();
    });

    pageController = PageController(initialPage: currPageIndex);

    // Initialize the page the user can navigate to
    var sessionPage = SessionPage(ref: _ref, controller: controller);
    var sessionNav = const NavigationDestination(
      icon: Icon(Icons.home, color: Colors.white),
      label: "Home",
    );

    var mapPage = MapPage(ref: _ref, controller: controller);
    var mapNav = const NavigationDestination(
      icon: Icon(Icons.map, color: Colors.white),
      label: "Map",
    );

    var usagePage = UsagePage(controller);
    var usageNav = const NavigationDestination(
      icon: Icon(Icons.data_thresholding, color: Colors.white),
      label: "Usage",
    );

    var profilePage = ProfileDisplayPage(widget.user!, controller);
    var profileNav = const NavigationDestination(
      icon: Icon(Icons.person, color: Colors.white),
      label: "Profile",
    );

    pages = [
      sessionPage,
      mapPage,
      usagePage,
      profilePage,
    ];

    // List of icons associated for each page
    destinations = [
      sessionNav,
      mapNav,
      usageNav,
      profileNav,
    ];
  }

  void accountSpecificSetup() {
    // Change the appbar depending on what page the user is on
    appBars = [
      mainAppBar(), // Session
      mainAppBar(), // Map
      mainAppBar(), // Usage
      profileAppBar(), // Profile
    ];

    // SUPER INSECURE DELETE WHEN DONE
    // TODO: (For testing) Delete
    List<String> admins = [
      'niiLt2Sf5OTakdnuAqpMVBgrmZV2', // Booth Admin
      'wUxLN0owVqZGEIBeMOt9q6lVBzL2', // Booth Admin 2
    ];
    var adminMode = admins.contains(controller.student.uid);

    // TODO: (For testing) Delete
    // Display an extra tab for admin accounts
    if (adminMode) {
      // Admin app bar
      appBars.add(adminAppBar());
      // Admin page
      pages.add(AdminPage(ref: _ref, controller: controller));
      // Admin icon
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.settings),
        label: "Admin",
      ));
    }
  }

  Scaffold createUI() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBars[currPageIndex],
      // body: pages[currPageIndex],
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        onPressed: () {
          // // Navigate to the create session page
          // Navigator.pushNamed(context, '/create_session',
          //     arguments: {'user': controller.student});
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => CreateSessionPage(controller)),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          onDestinationSelected: (int i) {
            setState(() {
              currPageIndex = i;
              pageController.jumpToPage(currPageIndex);
            });
          },
          selectedIndex: currPageIndex,
          destinations: destinations,
        ),
      ),
    );
  }

  AppBar mainAppBar() {
    return AppBar(
      title: Text("Booth | Welcome ${controller.student.fullname}!"),
      actions: [
        // This button is linked to the logout method
        IconButton(
          onPressed: logout,
          icon: const Icon(Icons.logout),
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
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/Profile'),
                builder: (context) => CreateProfilePage(controller))
            );
            // await Navigator.pushNamed(
            //   context,
            //   '/create_profile',
            //   arguments: {"user": widget.user, "controller": controller},
            // );
            // Causes the page to update when user is done
            setState(() {
              currPageIndex = currPageIndex;
            });
          },
        ),
        // Settings Button
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsPage(
                  controller: controller,
                  user: widget.user!,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  AppBar adminAppBar() {
    return AppBar(
      title: const Text("Admin Page"),
      actions: [
        // This button is linked to the logout method
        IconButton(
          onPressed: logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  /// *********  HELPER METHODS  *****************
  // This method logs the user out
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  AlertDialog errorDialog() {
    return AlertDialog(
      title: const Text('Error has occured'),
      content: const Text(
          'Your account cannot be found, please contact an administrator for help'),
      actions: [
        TextButton(
          onPressed: () {
            logout();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text("Cancel"),
        )
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
}
