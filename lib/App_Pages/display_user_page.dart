import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/friend_extension.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/MVC/block_extension.dart';

class UserDisplayPage extends StatefulWidget {
  final BoothController controller;
  final String userKey;
  final bool fromRequest;
  // No way to know the previous page from the navigator without more complicated
  // code so I passed an argument instead
  const UserDisplayPage(this.controller, this.userKey,
      this.fromRequest, // Change profile page if called from request page
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
            requests, widget.fromRequest);
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
  const UserProfilePage(this.controller, this.userKey, this.data, this.friends,
      this.requests, this.fromRequest,
      {super.key});

  @override
  State<StatefulWidget> createState() => _UserProfilePage();
}

class _UserProfilePage extends State<UserProfilePage> {
  var iconIndex = 0;
  @override
  Widget build(BuildContext context) {
    var data = widget.data;
    List<IconButton> trailingIcons = [
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
          onPressed: null, // TODO: Cancel friend request
          icon: Icon(Icons.mark_email_read_outlined)),
      // More options button
      IconButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SizedBox(
                      height: 95,
                      child:
                          // Block user button
                          ListTile(
                              onTap: () {
                                widget.controller.blockUser(widget.userKey);
                              },
                              contentPadding:
                                  const EdgeInsets.only(left: 16, right: 8),
                              title: const Text("Block",
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 20)),
                              leading: Icon(Icons.block, color: Colors.red)));
                });
          },
          icon: Icon(Icons.more_vert))
    ];
    if (widget.friends.containsKey(widget.userKey)) {
      iconIndex = 1;
    }
    if (widget.requests.containsKey(widget.userKey)) {
      iconIndex = 2;
    }
    return Scaffold(
        appBar: AppBar(
          title: Text('${data['name'] as String}\'s Profile Page'),
          actions: [
            // Remove the trailing icon in the app bar if came from request page or if viewing self
            widget.fromRequest ||
                    widget.controller.student.key == widget.userKey
                ? const SizedBox.shrink()
                : trailingIcons[iconIndex],
            trailingIcons[3]
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (data["profile_picture"] != null) {
                    Navigator.of(context).push(PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (context, _, __) => ProfileImage(data)));
                  }
                },
                child: CachedProfilePicture(
                  name: data['name'],
                  imageUrl: data["profile_picture"],
                  fontSize: 30,
                  radius: 40,
                ),
              )),
              const SizedBox(height: 16.0),
              Text(
                'Name: ${data["name"]}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Institution: ${data['institution'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Major: ${data['major'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Year: ${data['year'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Courses: ${data['courses']?.join(", ") ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Study Preferences: ${data['studyPref'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Availability: ${data['availability'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ));
  }
}

class ProfileImage extends StatelessWidget {
  const ProfileImage(this.data, {super.key});

  final Map<dynamic, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.8),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    "Tap to dismiss",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        CachedNetworkImage(
                          imageUrl: data["profile_picture"],
                          progressIndicatorBuilder: (context, url, progress) =>
                              Center(
                            child: CircularProgressIndicator(
                                value: progress.progress),
                          ),
                        )
                      ],
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
