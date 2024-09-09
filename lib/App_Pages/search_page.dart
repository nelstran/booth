import 'dart:collection';

import 'package:flutter/material.dart';

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
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: getUsers(controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        }
        Map<dynamic, dynamic> users = snapshot.data!;
        // final List<String> suggestionList = query.isEmpty
        //     ? []
        //     : (users.values.toList() as List<String>)
        //         .where(
        //             (item) => item.toLowerCase().contains(query.toLowerCase()))
        //         .toList();
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
            return ListTile(
              trailing: const Icon(Icons.add),
              title: Text(name),
              onTap: () {
                // Change Later to show the users profile/session examples
                query = name;
                controller.sendFriendRequest(userKey);
                // Show the search results based on the selected suggestion.
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
