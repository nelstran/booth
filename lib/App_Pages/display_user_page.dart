import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/friends_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class UserDisplayPage extends StatelessWidget {
  
  final BoothController controller;
  final String userKey;
  const UserDisplayPage(
    this.controller,
    this.userKey,
    {super.key}
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Fetches the user's name
      future: controller.getUserProfile(userKey),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile Page')
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("This user has not setup their profile page yet."),
                  // ElevatedButton(
                  //   onPressed: (){
                  //     controller.sendFriendRequest(userKey);
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blue,
                  //   ),
                  //   child: const Text(
                  //     "Send friend request",
                  //     style: TextStyle(color: Colors.black),
                  //   ),
                  // ),
                ],
              )
            ),
          );
        }
        Map<dynamic, dynamic> data = snapshot.data;
        return UserProfilePage(controller, data);
      },
    );
  }
}

class UserProfilePage extends StatelessWidget {
  const UserProfilePage(
    this.controller,
    this.data,
    {super.key}
    );

  final Map data;
  final BoothController controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${data['name'] as String}\'s Profile Page')
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
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey[500],
                ),
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