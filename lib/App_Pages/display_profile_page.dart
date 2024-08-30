import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class ProfileDisplayPage extends StatelessWidget {
  const ProfileDisplayPage({
    super.key,
    required this.user,
    required this.controller,
  });
  final BoothController controller;
  final User user;

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
                onPressed: (){
                  Navigator.pushNamed(
                    context, '/create_profile',
                    arguments: {'user': user}
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "Create Profile",
                  style: TextStyle(color: Colors.black),
                  ),
                )

            );
        }

        Map<dynamic, dynamic> data = snapshot.data;
        return ProfilePage(data: data);
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.data,
  });

  final Map data;
  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}