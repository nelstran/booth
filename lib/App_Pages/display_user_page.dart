import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';


class UserDisplayPage extends StatefulWidget {
  final BoothController controller;
  final String userKey;
  final bool fromRequest;
  // No way to know the previous page from the navigator without more complicated
  // code so I passed an argument instead
  const UserDisplayPage (
    this.controller,
    this.userKey,
    this.fromRequest, // Change profile page if called from request page
    {super.key}
  );
  
  @override
  State<StatefulWidget> createState() => _UserDisplayPage();
}
class _UserDisplayPage extends State<UserDisplayPage> {
  @override
  Widget build(BuildContext context) {
    if (!widget.fromRequest){
      
    }
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
              )
            ),
          );
        }
        Map<dynamic, dynamic> data = snapshot.data[0];
        Map<dynamic, dynamic> friends = snapshot.data[1];
        Map<dynamic, dynamic> requests = snapshot.data[2];
        return UserProfilePage(widget.controller, widget.userKey, data, friends, requests, widget.fromRequest);
      },
    );
  }

  /// Get the profile of given user and their profile picture to display
  Future<Map<dynamic, dynamic>> getUserProfile(userKey) async {
    Map<dynamic, dynamic> profile = {};
    Map<dynamic, dynamic> json = await widget.controller.getUserEntry(userKey);
    String? pfp = await widget.controller.retrieveProfilePicture(json['uid']);
    profile["profile_picture"] = pfp;
    if (json.containsKey('profile')){
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
  const UserProfilePage(
    this.controller,
    this.userKey,
    this.data,
    this.friends,
    this.requests,
    this.fromRequest,
    {super.key}
  );
  
  @override
  State<StatefulWidget> createState() => _UserProfilePage();
}
class _UserProfilePage extends State<UserProfilePage> {
  var iconIndex = 0;
  @override
  Widget build(BuildContext context) {
    var data = widget.data;
    List<IconButton> trailingIcons = [
      IconButton( // Add friend
        onPressed: (){
          widget.controller.sendFriendRequest(widget.userKey);
          // Change icon to 'request sent' when sending friend request
          setState((){
            iconIndex = 2;
          });
        }, 
        icon: const Icon(Icons.person_add_outlined)
      ),
      const IconButton( // Already friends
        // color: Colors.green,
        onPressed: null, 
        icon: Icon(Icons.check)
      ),
      const IconButton( // Request sent
        onPressed: null, // TODO: Cancel friend request 
        icon: Icon(Icons.mark_email_read_outlined)
      ),
    ];
    if (widget.friends.containsKey(widget.userKey)){
      iconIndex = 1;
    }
    if(widget.requests.containsKey(widget.userKey)){
      iconIndex = 2;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${data['name'] as String}\'s Profile Page'),
        actions: [
          // Remove the trailing icon in the app bar if came from request page
          !widget.fromRequest ? trailingIcons[iconIndex] : const SizedBox.shrink()
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                child: ProfilePicture(
                    name: "${data['name']}",
                    radius: 40,
                    fontsize: 30,
                    img: data["profile_picture"],
                  )
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Name: ${data["name"]}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      )
    );
  }
}