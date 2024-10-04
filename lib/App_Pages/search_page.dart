import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/display_user_page.dart';
import 'package:flutter_application_1/MVC/friend_extension.dart';
import 'package:flutter_application_1/MVC/session_extension.dart';

import '../MVC/booth_controller.dart';
import 'expanded_session_page.dart';

class SearchPage extends SearchDelegate<String> {
  late final BoothController controller;
  bool searchForUsers = true; // New state to toggle between users and sessions

  SearchPage({required this.controller});

  @override
  String get searchFieldLabel =>
      searchForUsers ? 'Search for users...' : 'Search for sessions...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
      IconButton(
        // Toggle button between searching users and sessions
        icon: Icon(searchForUsers ? Icons.person : Icons.event),
        onPressed: () {
          searchForUsers = !searchForUsers; // Toggle state
          query = ''; // Clear the query
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: searchForUsers
          ? getUsers(controller)
          : getSessions(controller), // Toggle between users and sessions
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(searchForUsers ? 'No Users' : 'No Sessions'),
          );
        }

        Map<dynamic, dynamic> results = snapshot.data!;
        final List<String> searchResults = (results.values.toList()
                as List<String>)
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
      future: searchForUsers
          ? getUsers(controller)
          : getSessions(controller), // Toggle between users and sessions
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        }

        Map<dynamic, dynamic> suggestions = snapshot.data!;
        Map<String, String> suggestionList = {};

        if (query.isNotEmpty) {
          for (var key in suggestions.keys) {
            if (suggestions[key]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase())) {
              suggestionList[key] = suggestions[key];
            }
          }
        }

        if (suggestionList.isEmpty && query.isNotEmpty) {
          return Center(
            child:
                Text(searchForUsers ? "No users found" : "No sessions found"),
          );
        }

        return ListView.builder(
          itemCount: suggestionList.length,
          itemBuilder: (context, index) {
            var name = suggestionList.values.elementAt(index);
            var key = suggestionList.keys.elementAt(index);

            return ListTile(
              title: Text(name),
              onTap: () {
                query = "";
                // Handle the navigation based on the selected result.
                if (searchForUsers) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          UserDisplayPage(controller, key, false),
                    ),
                  );
                } else {
                  // Navigate to session display page
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ExpandedSessionPage(key, controller),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Future<Map<dynamic, dynamic>> getUsers(BoothController controller) async {
    Map<dynamic, dynamic> users = await controller.getUsers();
    Map<String, String> userList = {};
    users.forEach((key, value) {
      if (!(value as Map).containsKey('name')) {
        return;
      }
      String name = value['name'] as String;
      String userKey = key as String;
      userList[userKey] = name;
    });
    return userList;
  }

  Future<Map<dynamic, dynamic>> getSessions(BoothController controller) async {
    Map<dynamic, dynamic> sessions = await controller.getSessions();
    Map<String, String> sessionList = {};
    sessions.forEach((key, value) {
      if (!(value as Map).containsKey('title')) {
        return;
      }
      String name = value['title'] as String;
      String sessionKey = key as String;
      sessionList[sessionKey] = name;
    });
    return sessionList;
  }
}
