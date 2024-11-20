import 'package:Booth/App_Pages/saved_sessions_page.dart';
import 'package:Booth/MVC/friend_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/friends_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:image_picker/image_picker.dart';

/// Page to display profile, friends, and session history of logged in user
class ProfileDisplayPage extends StatefulWidget {
  final BoothController controller;
  final User user;
  const ProfileDisplayPage(this.user, this.controller, {super.key});

  @override
  State<ProfileDisplayPage> createState() => _ProfileDisplayPage();
}

class _ProfileDisplayPage extends State<ProfileDisplayPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
        stream: widget.controller.profileRef.onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          Map<dynamic, dynamic> data = snap.data!.snapshot.value as Map;
          return ProfilePage(widget.controller, data);
        });
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage(this.controller, this.data, {super.key});

  final Map data;
  final BoothController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  String profileName = "";
  double profileRadius = 0;
  double fontSize = 0;
  String? profileImg = "";
  late FriendsPage friendsPage;
  late SavedSessionsPage savedSessionsPage;

  @override
  void initState() {
    super.initState();
    // Initialize with data from widget
    profileName =
        "${widget.data["name"] ?? widget.controller.student.fullname}";
    profileRadius = 60;
    fontSize = 40;
    profileImg = null;
    friendsPage = FriendsPage(widget.controller);
    savedSessionsPage = SavedSessionsPage(widget.controller);
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context){
    super.build(context);
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

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: profileHeader(context, profilePicture, major, year, institution)),
          ),
          Expanded(
            flex: 1,
            child: TabBar(
              indicatorColor: Colors.blue,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.only(bottom:10),
              unselectedLabelColor: const Color.fromARGB(255, 68, 68, 68),
              labelColor: Colors.white,
              tabs: [
                const Icon(Icons.person),
                Stack(
                  children: [
                    const Icon(Icons.people_outline),
                    Positioned(
                      top: -1,
                      right: -1,
                      child: StreamBuilder(
                        stream: widget.controller.studentRef().child("friends").onValue,
                        builder: (context, snapshot) {
                          return FutureBuilder(
                            future: widget.controller.getRequests(false), 
                            builder: (context, snapshot){
                              if (!snapshot.hasData){
                                return const SizedBox.shrink();
                              }
                              bool hasReqs = snapshot.data!.isNotEmpty;
                              if (!hasReqs){
                                return const SizedBox.shrink();
                              }
                              return SizedBox(
                                height: 10,
                                width: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 1),
                                  ),
                                ),
                              );
                            });
                        }
                      ),
                    )
                  ]
              ),
                const Icon(Icons.history)
              ]
            ),
          ),
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical:10),
              child: TabBarView(
                children: [
                  profileTab(studyPref, availability, courses),
                  friendsPage,
                  savedSessionsPage
                ]
              ),
            ),
          )
        ],
      ),
    );
  }

  Padding profileHeader(BuildContext context, String? profilePicture, String major, String year, String institution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: pfpWithEdit(context, profilePicture)
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

  Stack pfpWithEdit(BuildContext context, String? profilePicture) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FutureBuilder(
          future: widget.controller.getProfilePictureByUID(null, true),
          builder: (context, snapshot) {
            profileImg = snapshot.data;
            return CachedProfilePicture(
              name: profileName,
              radius: profileRadius,
              imageUrl: profileImg,
              fontSize: fontSize,
            );
          },
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: GestureDetector(
            onTap: () async {
              showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Select Profile Picture"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("Upload from Gallery"),
                          onTap: () async {
                            Navigator.pop(context);
                            ImagePicker imagePicker = ImagePicker();
                            XFile? file = await imagePicker.pickImage(
                                source: ImageSource.gallery);
                            if (file == null) return;
                            try {
                              await widget.controller
                                  .uploadProfilePicture(file,
                                      widget.controller.student.uid);
                              profilePicture = await widget.controller
                                  .retrieveProfilePicture(
                                      widget.controller.student.uid);
                              setState(() {
                                profileImg = profilePicture;
                              });
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Please Upload an Image')));
                              return;
                            }
                          },
                        ),
                        ListTile(
                          title: const Text("Take a Picture"),
                          onTap: () async {
                            Navigator.pop(context);
                            ImagePicker imagePicker = ImagePicker();
                            XFile? file = await imagePicker.pickImage(
                                source: ImageSource.camera);
                            if (file == null) return;
                            try {
                              await widget.controller
                                  .uploadProfilePicture(file,
                                      widget.controller.student.uid);
                              profilePicture = await widget.controller
                                  .retrieveProfilePicture(
                                      widget.controller.student.uid);
                              setState(() {
                                profileImg = profilePicture;
                              });
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Please Take a Picture')));
                              return;
                            }
                          },
                        ),
                        ListTile(
                          title: const Text("Remove Profile Picture"),
                          onTap: () async {
                            Navigator.pop(context);
                            await widget.controller
                                .deleteProfilePicture();
                            setState(() {
                              profileImg = null;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(
                  Icons.edit,
                  color: Colors.black,
                  size: 25.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  } 
}