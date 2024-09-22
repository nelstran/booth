import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/friends_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;

class ProfileDisplayPage extends StatelessWidget {
  final BoothController controller;
  final User user;
  const ProfileDisplayPage(this.user, this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Fetches the user's name
      future: controller.getUserProfile(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create_profile',
                  arguments: {'user': user});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              "Create Profile",
              style: TextStyle(color: Colors.black),
            ),
          ));
        }
        Map<dynamic, dynamic> data = snapshot.data;
        return ProfilePage(controller, data);
      },
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage(this.controller, this.data, {super.key});

  final Map data;
  final BoothController controller;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? profileName = "";
  double profileRadius = 0;
  double fontSize = 0;
  String? profileImg = "";

  @override
  void initState() {
    super.initState();
    // Initialize with data from widget
    profileName = "${widget.data["name"]}";
    profileRadius = 40;
    fontSize = 30;
    profileImg = null;
  }

  @override
  Widget build(BuildContext context) {
    // String? profilePicture;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder(
            future: getProfilePicture(widget.controller),
            builder: (context, snapshot){
              if (!snapshot.hasData){
                return const Center(child: CircularProgressIndicator());
              }
              else if (snapshot.hasError){
                profileImg = null;
              }
              profileImg = snapshot.data;
              return Center(
              child: InkWell(
                  onTap: () async {
                    // Change profile picture properties on tap
                    //String? newProfileImg = await _getProfilePictureDest(context, widget.controller);
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
                                  print('${file?.path}');
                                  if (file == null) return;
                                  // upload to firebase storage
                                  try {
                                    // Upload the image to firebase storage, and retrieve img URL
                                    String pfpURL = await widget.controller
                                        .uploadProfilePictureStorage(file);
                                    // Update the profile picture URL in firestore
                                    await widget.controller
                                        .uploadProfilePictureFireStore(pfpURL,
                                            widget.controller.student.uid);
                                    // Retrieve the profile picture URL
                                    profileImg = await widget.controller
                                        .retrieveProfilePicture(
                                            widget.controller.student.uid);
                                    // print("Profile Picture: $profilePicture");
                                    setState(() {
                                      // // Upload new profile pictur
                                      // profileImg = profilePicture;
                                    });
                                  } catch (error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Please Upload an Image')));
                                    return;
                                  }
                                },
                              ),
                              ListTile(
                                title: const Text("Take a Picture"),
                                onTap: () async {
                                  Navigator.pop(context,
                                      "Taking a picture option selected");
                                  ImagePicker imagePicker = ImagePicker();
                                  XFile? file = await imagePicker.pickImage(
                                      source: ImageSource.camera);
                                  if (file == null) return;
                                  // upload to firebase storage
                                  try {
                                    // Upload the image to firebase storage, and retrieve img URL
                                    String pfpURL = await widget.controller
                                        .uploadProfilePictureStorage(file);
                                    // Update the profile picture URL in firestore
                                    await widget.controller
                                        .uploadProfilePictureFireStore(pfpURL,
                                            widget.controller.student.uid);
                                    // Retrieve the profile picture URL
                                    profileImg = await widget.controller
                                        .retrieveProfilePicture(
                                            widget.controller.student.uid);
            
                                    setState(() {
                                      // Upload new profile pictur
                                      // profileImg = profilePicture;
                                    });
                                  } catch (error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Please Take a Picture')));
                                    return;
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: ProfilePicture(
                    name: profileName!,
                    radius: profileRadius,
                    fontsize: fontSize,
                    img: profileImg,
                  )
                  // child: CircleAvatar(
                  //   radius: 30,
                  //   backgroundColor: Colors.grey[200],
                  //   child: Icon(
                  //     Icons.person,
                  //     size: 50,
                  //     color: Colors.grey[500],
                  //   ),
                  // ),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          Text(
            'Name: ${widget.data["name"]}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Institution: ${widget.data['institution'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Major: ${widget.data['major'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Year: ${widget.data['year'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Courses: ${widget.data['courses']?.join(", ") ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Study Preferences: ${widget.data['studyPref'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Availability: ${widget.data['availability'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          ElevatedButton(
              child: const Text("My Friends"),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FriendsPage(widget.controller),
                  ),
                );
              })
        ],
      ),
    );
  }
  
  /// Helper future method to fetch the profile picture Image URL from the database and checks
  /// if the URL is valid; if it is not valid, return null, else return the valid URL
  Future<String?> getProfilePicture(BoothController controller) async  {
    // Get URL from Firestore
    String? pfp = await widget.controller.retrieveProfilePicture(widget.controller.student.uid);
    if (pfp == null){
      return pfp;
    }
    else{
      // Grabs response of given url
      final response = await http.get(Uri.parse(pfp));
      if (response.statusCode == 200){
        return pfp;
      }
      else{
        return null;
      }
    }
  }
}
