import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:Booth/UI_components/focus_image.dart';
import 'package:flutter/material.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/friend_extension.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/block_extension.dart';

/// Same as profile page but displays only the profile of the 
/// viewed user
class UserDisplayPage extends StatefulWidget {
  final BoothController controller;
  final String userKey;
  final bool fromRequest;
  final bool fromBlocked;
  // No way to know the previous page from the navigator without more complicated
  // code so I passed an argument instead
  const UserDisplayPage(this.controller, this.userKey,
      this.fromRequest, // Change profile page if called from request page
      this.fromBlocked, 
      {super.key});

  @override
  State<StatefulWidget> createState() => _UserDisplayPage();
}

class _UserDisplayPage extends State<UserDisplayPage> {
  @override
  Widget build(BuildContext context) {
    if (!widget.fromRequest) {}
    return FutureBuilder(
      // Fetches the user's name
      future: Future.wait([
        getUserProfile(widget.userKey),
        widget.controller.getFriends(),
        widget.controller.getRequests(true),
      ]),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile Page'),
            ),
            body: const Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("This user has not setup their profile page yet."),
              ],
            )),
          );
        }
        Map<dynamic, dynamic> data = snapshot.data[0];
        Map<dynamic, dynamic> friends = snapshot.data[1];
        Map<dynamic, dynamic> requests = snapshot.data[2];
        return UserProfilePage(widget.controller, widget.userKey, data, friends,
            requests, widget.fromRequest, widget.fromBlocked);
      },
    );
  }

  /// Get the profile of given user and their profile picture to display
  Future<Map<dynamic, dynamic>> getUserProfile(userKey) async {
    Map<dynamic, dynamic> profile = {};
    Map<dynamic, dynamic> json = await widget.controller.getUserEntry(userKey);
    String? pfp = await widget.controller.retrieveProfilePicture(json['uid']);
    profile["profile_picture"] = pfp;
    if (json.containsKey('profile')) {
      profile.addEntries((json['profile'] as Map).entries);
    }
    return profile;
  }
}

class UserProfilePage extends StatefulWidget {
  final Map data;
  final BoothController controller;
  final String userKey;
  final Map<dynamic, dynamic> friends;
  final Map<dynamic, dynamic> requests;
  final bool fromRequest;
  final bool fromBlocked;
  const UserProfilePage(this.controller, this.userKey, this.data, this.friends,
      this.requests, this.fromRequest, this.fromBlocked,
      {super.key});

  @override
  State<StatefulWidget> createState() => _UserProfilePage();
}

class _UserProfilePage extends State<UserProfilePage> {
  String profileName = "";
  double profileRadius = 0;
  double fontSize = 0;
  String? profileImg = "";
  
  var iconIndex = 0;
  List<IconButton> trailingIcons = [];

  @override
  void initState() {
    super.initState();
    // Initialize with data from widget
    profileName =
        "${widget.data["name"] ?? widget.controller.student.fullname}";
    profileRadius = 60;
    fontSize = 40;
    profileImg = null;

    trailingIcons = [
      IconButton(
          // Add friend
          onPressed: () {
            widget.controller.sendFriendRequest(widget.userKey);
            // Change icon to 'request sent' when sending friend request
            setState(() {
              iconIndex = 2;
            });
          },
          icon: const Icon(Icons.person_add_outlined)),
      const IconButton(
          // Already friends
          // color: Colors.green,
          onPressed: null,
          icon: Icon(Icons.check)),
      const IconButton(
          // Request sent
          onPressed: null,
          icon: Icon(Icons.mark_email_read_outlined)),
      // More options button
      IconButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SizedBox(
                      height: 75,
                      child:
                          // Block user button
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: ListTile(
                                onTap: () {
                                  confirmBlockDialog(context, profileName, widget.userKey);
                                },
                                contentPadding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                title: const Text("Block",
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 20)),
                                leading: const Icon(Icons.block, color: Colors.red)),
                          ));
                });
          },
          icon: const Icon(Icons.more_vert))
    ];
  }

  @override
  Widget build(BuildContext context){
    if (widget.friends.containsKey(widget.userKey)) {
      iconIndex = 1;
    }
    if (widget.requests.containsKey(widget.userKey)) {
      iconIndex = 2;
    }
    String? profilePicture;
    profileName =
        "${widget.data["name"] ?? widget.controller.student.fullname}";
    String institution = widget.data["institution"];
    String major = widget.data["major"] ?? "";
    major = major.isEmpty ? "Undecided" : major;

    String year = widget.data['year'] ?? "";
    year = year.isEmpty ? "Enrolled" : year;

    List courses = widget.data['courses'] ?? [];

    String studyPref = widget.data['studyPref'] ?? "";
    studyPref = studyPref.isEmpty ? "No preferences" : studyPref;

    String availability = widget.data['availability'] ?? "";
    availability = availability.isEmpty ? "Availability not stated" : availability;

    return Scaffold(
      appBar: AppBar(
        title: Text(profileName),
        actions: [
            // Remove the trailing icon in the app bar if came from request page, block page, or if viewing self
            widget.fromRequest || widget.fromBlocked ||
                widget.controller.student.key == widget.userKey
                ? const SizedBox.shrink()
                : trailingIcons[iconIndex],
            widget.controller.student.key == widget.userKey || widget.fromBlocked
              ? const SizedBox.shrink()
              : trailingIcons[3],
            widget.fromBlocked
            ? unblockButton(context, widget.data["name"], widget.userKey)
            : const SizedBox.shrink()
          ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: profileHeader(context, profilePicture, major, year, institution)),
          ),
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical:10),
              child: profileTab(studyPref, availability, courses),
            ),
          )
        ],
      ),
    );
  }

  Widget profileTab(String studyPref, String availability, List<dynamic> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.blue,
                width: 4,
              )
            )
          ),
          child: ListTile(
            title: const Text(
              "Study Preferences",
              style: TextStyle(
                fontWeight: FontWeight.bold
              )),
            subtitle: Text(studyPref),
          ),
        ),
        const SizedBox(
          height: 10
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.blue,
                width: 4,
              )
            )
          ),
          child: ListTile(
            title: const Text(
              "Availability",
              style: TextStyle(
                fontWeight: FontWeight.bold
              )),
            subtitle: Text(availability),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Courses",
          style: TextStyle(
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue[700]
          ),
        ),                
        SizedBox(
          height: 250,
          width: 350,
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 5,
            crossAxisCount: 2,
            children: List.generate(courses.length >= 12 ? 12 : courses.length, (index){
              if (index == 11){
                return Text(
                "+ ${courses.length - 12} more",
                style: const TextStyle(
                  height: 2,
                  fontSize: 18
                )
              );
              }
              return Text(
                "- ${courses[index]}",
                style: const TextStyle(
                  height: 2,
                  fontSize: 18
                )
              );
            })
          )
        )
      ],
    );
  }

  Padding profileHeader(BuildContext context, String? profilePicture, String major, String year, String institution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: FutureBuilder(
              future: widget.controller.getProfilePictureByKey(widget.userKey, true),
              builder: (context, snapshot) {
                profileImg = snapshot.data;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (profileImg != null) {
                      // Navigator.of(context).push(PageRouteBuilder(
                      //     opaque: false,
                      //     pageBuilder: (context, _, __) => ProfileImage(data)));
                      Navigator.of(context).push(PageRouteBuilder(
                        opaque: false,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (context, _, __) =>
                          FocusImage(profileImg!)
                      ));
                    }
                  },
                  child: CachedProfilePicture(
                    name: profileName,
                    imageUrl: profileImg,
                    fontSize: fontSize,
                    radius: profileRadius,
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    major,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18
                    )
                  ),
                  const Divider(
                    thickness: 4,
                  ),
                  RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: year
                        ),
                        const TextSpan(
                          text: " at ",
                          style: TextStyle(
                            // fontWeight: FontWeight.w300
                          )
                        ),
                        TextSpan(
                          text: institution
                        ),
                      ]
                    )
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

   TextButton unblockButton(BuildContext context, String userName, userKey) {
    return TextButton(
      child: const Text(
        "Unblock  ", 
        style: TextStyle(
          color:Colors.white,
          fontWeight: FontWeight.bold
        )
      ),
      onPressed: () {
        confirmUnblockDialog(context, userName, userKey);
      },
    );
  }

  /// Method to display a dialog to confirm that users want to block the viewed user
  Future<bool> confirmUnblockDialog(
      BuildContext context, String userName, String userId) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Unblock'),
          content: Text('Are you sure you want to unblock $userName?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Unblock'),
              onPressed: () {
                widget.controller.unblockUser(userId);

                // Pop dialog
                Navigator.pop(context);
                // Pop screen
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

  /// Method to display a dialog to confirm that users want to block the viewed user
  Future<bool> confirmBlockDialog(
      BuildContext context, String userName, String userId) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block user?'),
          content: Text('Are you sure you want to block $userName?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Block'),
              onPressed: () {
                widget.controller.blockUser(userId);

                // Pop dialog
                Navigator.pop(context);
                // Pop modal
                Navigator.pop(context);
                // Pop screen
                Navigator.pop(context);
                // Show snackbar for confirmation (optional)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blocked $userName'),
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
