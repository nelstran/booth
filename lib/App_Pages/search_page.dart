import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/display_user_page.dart';

import '../MVC/booth_controller.dart';

class SearchPage extends SearchDelegate<String> {
  late final BoothController controller;
  SearchPage({required this.controller});

  // Mock data, need this to be a list of users from the database
  final List<String> searchList = [
    "Brayden",
    "Bob",
    "Nelson",
    "Noah",
    "Jack",
    "Joel",
    "Leena",
    "Laura"
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
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
        Map<String, String> suggestionList = {};
        if (query.isNotEmpty){
          for(var key in users.keys){
            if (users[key].toString().toLowerCase().contains(query.toLowerCase())){
              suggestionList[key] = users[key];
            }
          }
        }
        return ListView.builder(
          itemCount: suggestionList.length,
          itemBuilder: (context, index) {
            String name = suggestionList.values.elementAt(index);
            String userKey = suggestionList.keys.elementAt(index);
            List<IconButton> trailingIcons = [
              IconButton( // Add friend
                onPressed: (){
                  controller.sendFriendRequest(userKey); // TODO: Change icon when this is tapped
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
            IconButton listIcon = trailingIcons[0];
            if (snapshot.data![1].containsKey(userKey)){
              listIcon = trailingIcons[1];
            }
            if(snapshot.data![2].containsKey(userKey)){
              listIcon = trailingIcons[2];
            }
            return ListTile(
              trailing: listIcon,
              title: Text(name),
              onTap: () {
                // Show the search results based on the selected suggestion.
                query = name;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDisplayPage(controller, userKey),
                  ),
                );
                
              },
            );
          },
        );
      },
    );
  }

  Future<Map<dynamic, dynamic>> getUsers(BoothController controller) async {
    Map<dynamic, dynamic> users =
        await controller.getUsers(); // Await the Future

    Map<String, String> userList = {};

    users.forEach((key, value) {
      String name = value['name'] as String;
      String userKey = key as String;
      userList[userKey] = name;
    });

    return userList;
  }
}
