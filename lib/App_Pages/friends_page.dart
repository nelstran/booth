import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/display_user_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/App_Pages/requests_page.dart'; // Import the RequestsPage

class FriendsPage extends StatefulWidget{
  const FriendsPage(this.boothController, {super.key});
  final BoothController boothController;
  
  @override
  State<StatefulWidget> createState() => _FriendsPage();
  
}
class _FriendsPage extends State<FriendsPage> {

  @override
  Widget build(BuildContext context) {
    Future<Map<dynamic, dynamic>> requests = widget.boothController.getRequests(false);
    Future<Map<dynamic, dynamic>> friends = widget.boothController.getFriends();
    var requestsList = {};
    var friendsList = {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          requests,
          friends
        ]), 
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } 
          requestsList = snapshot.data![0];
          friendsList = snapshot.data![1];
          return Column(
            children: [
              if (snapshot.data![0].isNotEmpty) GestureDetector(
                onTap: () async {
                  // Navigate to the RequestsPage
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestsPage(controller: widget.boothController),
                    ),
                  );
                  setState(() {
                    requests = widget.boothController.getRequests(false);
                  });
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
                      Text("(${requestsList.length})"), // Show # of requests
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
              if (snapshot.data![1].isNotEmpty) Expanded(
                child: ListView.builder(
                  itemCount: friendsList.length,
                  itemBuilder: (context, index){
                    final userId = friendsList.keys.elementAt(index);
                    final userName = friendsList[userId] as String;
                
                    return Dismissible( // Dismissible allows swipe away actions
                      key: Key(userId), 
                      background: Container( 
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      // onDismissed: (direction) {
                      //   if (direction == DismissDirection.endToStart) {
                      //     showConfirmationDialog(context, userName, userId);
                      //   }
                      // },
                      confirmDismiss: (direction) {
                        return showConfirmationDialog(context, userName, userId);
                      },
                      child: Card(
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
                          trailing: PopupMenuButton<int>( //  Popup menu for options (currently remove friend option)
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 1,
                                child: Text('Remove Friend'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 1) {
                                showConfirmationDialog(context, userName, userId);
                              }
                            },
                          ),
                          onTap: () {
                            // Navigate to the profile page of the selected friend
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserDisplayPage(widget.boothController, userId),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                ),
              ) 
              else const Center(child: Text('No friends found'))
            ],
          );
        }
      )
    );
  }

  Future<bool> showConfirmationDialog(BuildContext context, String userName, String userId) async {
  bool confirm = false;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text('Are you sure you want to unfriend $userName ?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Remove'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, 
            ),
            onPressed: () {
              widget.boothController.removeFriend(userId);
              Navigator.pop(context);
              // Show snackbar for confirmation (optional)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed $userName from friends'),
                ),
              );
              confirm = true;
            },
          ),
        ],
      );
    },
  );
  return confirm;
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
