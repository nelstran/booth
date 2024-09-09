import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/App_Pages/requests_page.dart'; // Import the RequestsPage

class FriendsPage extends StatelessWidget {
  const FriendsPage(this.boothController, {super.key});
  final BoothController boothController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
      ),
      body: Column(
        children: [
          // Requests section with a clickable option
          GestureDetector(
            onTap: () {
              // Navigate to the RequestsPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestsPage(controller: boothController), 
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Requests",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FutureBuilder<Map<dynamic, dynamic>>(
                    future: boothController.getRequests(false), // Fetch friend requests
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text("(0)");
                      }
                      return Text("(${snapshot.data!.length})"); // Show # of requests
                    },
                  ),
                ],
              ),
            ),
          ),
          // Friends header
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Friends",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<dynamic, dynamic>>(
              future: boothController.getFriends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No friends found.'));
                }
                final friends = snapshot.data!;
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final userId = friends.keys.elementAt(index);
                    final userName = friends[userId] as String;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[500],
                          ),
                        ),
                        title: Text(
                          userName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            getStatusIndicator(userId),
                            const SizedBox(width: 8),
                            Text(getAvailability(userId)), 
                          ],
                        ),
                        onTap: () {
                          // TODO: Navigate to the profile page of the selected friend, Replace with actual logic
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: userId,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Function to return availability, replace with actual logic
  String getAvailability(String userId) {
    return "Online"; 
  }

  // Widget for availability status indicator 
  Widget getStatusIndicator(String userId) {
    final availability = getAvailability(userId);
    Color dotColor;

    switch (availability) {
      case "Online":
        dotColor = Colors.green;
        break;
      case "Away":
        dotColor = Colors.yellow;
        break;
      default:
        dotColor = Colors.grey;
        break;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
