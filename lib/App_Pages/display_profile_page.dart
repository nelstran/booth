import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/friends_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize with data from widget
    profileName =
        "${widget.data["name"] ?? widget.controller.student.fullname}";
    profileRadius = 60;
    fontSize = 40;
    profileImg = null;
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context){
    super.build(context);
    String? profilePicture;
    profileName =
        "${widget.data["name"] ?? widget.controller.student.fullname}";
    String institution = widget.data["institution"]; // Required
    String major = widget.data["major"] ?? "";
    major = major.isEmpty ? "Undecided" : "$major major";

    String year = widget.data['year'] ?? "";
    year = year.isEmpty ? "Enrolled" : year;

    List courses = widget.data['courses'] ?? [];

    String studyPref = widget.data['studyPref'] ?? "";
    studyPref = studyPref.isEmpty ? "No preferences" : studyPref;

    String availability = widget.data['availability'] ?? "";
    availability = availability.isEmpty ? "Availability not stated" : availability;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
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
                          profileName,
                          style: const TextStyle(
                            fontSize: 20
                          )
                        ),
                        const Divider(
                          thickness: 4,
                        ),
                        Text(major),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                children: [
                  TextSpan(
                    text: year
                  ),
                  const TextSpan(
                    text: " at the ",
                    style: TextStyle(
                      fontWeight: FontWeight.w300
                    )
                  ),
                  TextSpan(
                    text: institution
                  ),
                ]
              )
            )
          ),
          Expanded(
            flex: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Study Preferences\n",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 25,
                            decoration: TextDecoration.underline,
                            color: Colors.blue[700]
                          )
                        ),
                        TextSpan(
                          text: studyPref,
                          style: const TextStyle(
                            height: 2,
                            fontSize: 18
                          )
                        )
                      ]
                    )
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Availability\n",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 25,
                            decoration: TextDecoration.underline,
                            color: Colors.blue[700]
                          )
                        ),
                        TextSpan(
                          text: availability,
                          style: const TextStyle(
                            height: 2,
                            fontSize: 18
                          )
                        )
                      ]
                    )
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Courses",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 25,
                    decoration: TextDecoration.underline,
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
            )
          )
        ],
      ),
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
                        padding: const EdgeInsets.all(2.0),
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
  // @override
  // Widget build(BuildContext context) {
  //   super.build(context);
  //   String? profilePicture;
  //   profileName =
  //       "${widget.data["name"] ?? widget.controller.student.fullname}";

  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Center(
  //           child: Stack(
  //             alignment: Alignment.center,
  //             children: [
  //               FutureBuilder(
  //                 future: widget.controller.getProfilePictureByUID(null, true),
  //                 builder: (context, snapshot) {
  //                   profileImg = snapshot.data;
  //                   return CachedProfilePicture(
  //                     name: profileName,
  //                     radius: profileRadius,
  //                     imageUrl: profileImg,
  //                     fontSize: fontSize,
  //                   );
  //                 },
  //               ),
  //               Positioned(
  //                 bottom: 1,
  //                 right: 1,
  //                 child: GestureDetector(
  //                   onTap: () async {
  //                     showDialog<String>(
  //                       context: context,
  //                       builder: (BuildContext context) {
  //                         return AlertDialog(
  //                           title: const Text("Select Profile Picture"),
  //                           content: Column(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               ListTile(
  //                                 title: const Text("Upload from Gallery"),
  //                                 onTap: () async {
  //                                   Navigator.pop(context);
  //                                   ImagePicker imagePicker = ImagePicker();
  //                                   XFile? file = await imagePicker.pickImage(
  //                                       source: ImageSource.gallery);
  //                                   if (file == null) return;
  //                                   try {
  //                                     await widget.controller
  //                                         .uploadProfilePicture(file,
  //                                             widget.controller.student.uid);
  //                                     profilePicture = await widget.controller
  //                                         .retrieveProfilePicture(
  //                                             widget.controller.student.uid);
  //                                     setState(() {
  //                                       profileImg = profilePicture;
  //                                     });
  //                                   } catch (error) {
  //                                     ScaffoldMessenger.of(context)
  //                                         .showSnackBar(const SnackBar(
  //                                             content: Text(
  //                                                 'Please Upload an Image')));
  //                                     return;
  //                                   }
  //                                 },
  //                               ),
  //                               ListTile(
  //                                 title: const Text("Take a Picture"),
  //                                 onTap: () async {
  //                                   Navigator.pop(context);
  //                                   ImagePicker imagePicker = ImagePicker();
  //                                   XFile? file = await imagePicker.pickImage(
  //                                       source: ImageSource.camera);
  //                                   if (file == null) return;
  //                                   try {
  //                                     await widget.controller
  //                                         .uploadProfilePicture(file,
  //                                             widget.controller.student.uid);
  //                                     profilePicture = await widget.controller
  //                                         .retrieveProfilePicture(
  //                                             widget.controller.student.uid);
  //                                     setState(() {
  //                                       profileImg = profilePicture;
  //                                     });
  //                                   } catch (error) {
  //                                     ScaffoldMessenger.of(context)
  //                                         .showSnackBar(const SnackBar(
  //                                             content: Text(
  //                                                 'Please Take a Picture')));
  //                                     return;
  //                                   }
  //                                 },
  //                               ),
  //                               ListTile(
  //                                 title: const Text("Remove Profile Picture"),
  //                                 onTap: () async {
  //                                   Navigator.pop(context);
  //                                   await widget.controller
  //                                       .deleteProfilePicture();
  //                                   setState(() {
  //                                     profileImg = null;
  //                                   });
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         );
  //                       },
  //                     );
  //                   },
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: Colors.black, width: 1),
  //                     ),
  //                     child: const Padding(
  //                       padding: const EdgeInsets.all(2.0),
  //                       child: Icon(
  //                         Icons.edit,
  //                         color: Colors.black,
  //                         size: 16.0,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 16.0),
  //         Text(
  //           'Name: $profileName',
  //           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(height: 8.0),
  //         Text(
  //           'Institution: ${widget.data['institution'] ?? 'N/A'}',
  //           style: const TextStyle(fontSize: 16),
  //         ),
  //         const SizedBox(height: 8.0),
  //         Text(
  //           'Major: ${widget.data['major'] ?? 'N/A'}',
  //           style: const TextStyle(fontSize: 16),
  //         ),
  //         const SizedBox(height: 8.0),
  //         Text(
  //           'Year: ${widget.data['year'] ?? 'N/A'}',
  //           style: const TextStyle(fontSize: 16),
  //         ),
  //         const SizedBox(height: 8.0),
  //         Text(
  //           'Courses: ${widget.data['courses']?.join(", ") ?? 'N/A'}',
  //           style: const TextStyle(fontSize: 16),
  //         ),
  //         const SizedBox(height: 8.0),
  //         Text(
  //           'Study Preferences: ${widget.data['studyPref'] ?? 'N/A'}',
  //           style: const TextStyle(fontSize: 16),
  //         ),
  //         const SizedBox(height: 8.0),
  //         Text(
  //           'Availability: ${widget.data['availability'] ?? 'N/A'}',
  //           style: const TextStyle(fontSize: 16),
  //         ),
  //         ElevatedButton(
  //           child: const Text("My Friends"),
  //           onPressed: () {
  //             Navigator.of(context).push(
  //               MaterialPageRoute(
  //                 builder: (context) => FriendsPage(widget.controller),
  //               ),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
