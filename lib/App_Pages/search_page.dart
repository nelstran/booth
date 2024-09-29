import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/display_user_page.dart';
import 'package:flutter_application_1/MVC/friend_extension.dart';

import '../MVC/booth_controller.dart';

class SearchPage extends SearchDelegate<String> {
  late final BoothController controller;
  SearchPage({required this.controller});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          // When pressed here the query will be cleared from the search bar.
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      // Exit from the search screen.
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder
    (
      future: getUsers(controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Users'));
        }
        Map<dynamic, dynamic> users = snapshot.data!;
        final List<String> searchResults = (users.values.toList()as List<String>)
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(searchResults[index]),
              onTap: () {
                // Handle the selected search result.
                close(context, searchResults[index]);
              },
            );
          },
        );
      },
    );
  }
  @override
  Widget buildSuggestions(BuildContext context)  {
    return FutureBuilder(
      future: Future.wait([
        getUsers(controller),
        controller.getFriends(),
        controller.getRequests(true),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        }
        Map<dynamic, dynamic> users = snapshot.data![0];
        Map<dynamic, dynamic> friends = snapshot.data![1];
        Map<dynamic, dynamic> requests = snapshot.data![2];

        Map<String, String> suggestionList = {};
        if (query.isNotEmpty){
          for(var key in users.keys){
            if (users[key].toString().toLowerCase().contains(query.toLowerCase())){
              suggestionList[key] = users[key];
            }
          }
        }

        if (suggestionList.isEmpty && query.isNotEmpty){
          return const Center(
            child: Text("No users found"),
          );
        }

        return ListView.builder(
          itemCount: suggestionList.length,
          itemBuilder: (context, index) {
            var iconIndex = 0;
            return StatefulBuilder(
              builder: (context, setState) {
                String name = suggestionList.values.elementAt(index);
                String userKey = suggestionList.keys.elementAt(index);
                if (userKey == controller.student.key){
                  return const SizedBox.shrink();
                }
                List<IconButton> trailingIcons = [
                  IconButton( // Add friend
                    onPressed: (){
                      controller.sendFriendRequest(userKey);
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
                if (friends.containsKey(userKey)){
                  iconIndex = 1;
                }
                if(requests.containsKey(userKey)){
                  iconIndex = 2;
                }
                return ListTile(
                  trailing: trailingIcons[iconIndex],
                  title: Text(name),
                  onTap: () {
                    // Show the search results based on the selected suggestion.
                    query = name;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserDisplayPage(controller, userKey, false),
                      ),
                    );
                  },
                );
              },
            );
          }
        );
      },
    );
  }

  Future<Map<dynamic, dynamic>> getUsers(BoothController controller) async {
    Map<dynamic, dynamic> users =
        await controller.getUsers(); // Await the Future

    Map<String, String> userList = {};

    users.forEach((key, value) {
      // Makes sure search does not break on faulty entry in realtime database
      if (!(value as Map).containsKey('name')){
        return;
      }
      String name = value['name'] as String;
      String userKey = key as String;
      userList[userKey] = name;
    });

    return userList;
  }
}
