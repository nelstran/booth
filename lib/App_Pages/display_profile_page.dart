import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class ProfileDisplayPage extends StatelessWidget {
  const ProfileDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User user = FirebaseAuth.instance.currentUser!;
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final BoothController controller = BoothController(ref);

    return FutureBuilder<String>(
      // Fetches the user's name
      future: controller.fetchAccountInfo(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: Colors.blue,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('User not found.', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16.0),
                 ],
              ),
            ),
          );
        }

        final fullName = snapshot.data!;
        // Fetch additional profile data if profile exists
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchAdditionalProfileData(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (profileSnapshot.hasError) {
              return Center(child: Text('Error: ${profileSnapshot.error}'));
            } else if (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty) {
              return const Center(child: Text('No profile information found.'));
            }

            final data = profileSnapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                backgroundColor: Colors.blue,
                actions: [
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/edit_profile',
                        arguments: user,
                      );
                    },
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Implement delete profile here if desired
                    },
                  ),
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
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Name: $fullName',
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
              ),
              // Navigation logic (modify as needed)
              bottomNavigationBar: BottomNavigationBar(
                onTap: (int index) {
                  switch (index) {
                    case 0:
                      Navigator.pushNamed(context, '/');
                      break;
                    case 1:
                      Navigator.pushNamed(context, '/map');
                      break;
                    case 2:
                      Navigator.pushNamed(context, '/usage');
                      break;
                    case 3:
                      // Do nothing as we're already on the Profile page
                      break;
                  }
                },
                currentIndex: 3, // Highlight the Profile tab
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
                backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                unselectedIconTheme: Theme.of(context).bottomNavigationBarTheme.unselectedIconTheme,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    label: "Map",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.data_thresholding),
                    label: "Usage",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile",
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Fetches the profile data from the firebase realtime database
  Future<Map<String, dynamic>> fetchAdditionalProfileData(User user) async {
    final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}/profile').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data;
    } else {
      return {};
    }
  }
}