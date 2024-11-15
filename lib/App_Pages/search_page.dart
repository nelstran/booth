import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/display_user_page.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/block_extension.dart';
import '../MVC/booth_controller.dart';
import 'expanded_session_page.dart';

class SearchPage extends SearchDelegate<String> {
  late final BoothController controller;

  SearchPage({required this.controller});

  @override
  String get searchFieldLabel => 'Search...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
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
    return buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildSearchResults(context);
  }

  Widget buildSearchResults(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Users and Sessions
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Sessions'),
            ],
            labelColor: Colors.blue, // active tabs
            unselectedLabelColor: Colors.grey, // inactive tabs
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: Colors.blueAccent),
              insets: EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                searchResultsView(context, true), // For users
                searchResultsView(context, false), // For sessions
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget searchResultsView(BuildContext context, bool searchForUsers) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<Map<dynamic, dynamic>>(
            future:
                searchForUsers ? getUsers(controller) : getSessions(controller),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error occurred'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                      searchForUsers ? 'No Users Found' : 'No Sessions Found'),
                );
              }

              Map<dynamic, dynamic> suggestionList = snapshot.data!;

              // Filter the suggestions based on the query
              final filteredSuggestions = suggestionList.entries
                  .where((entry) =>
                      entry.value.toLowerCase().contains(query.toLowerCase()))
                  .toList();

              if (query.isEmpty) {
                return const Center(child: Text('Start searching...'));
              } else if (filteredSuggestions.isEmpty) {
                return Center(
                  child: Text(
                      searchForUsers ? 'No Users Found' : 'No Sessions Found'),
                );
              }

              return ListView.builder(
                itemCount: filteredSuggestions.length,
                itemBuilder: (context, index) {
                  var name = filteredSuggestions[index].value;
                  var key = filteredSuggestions[index].key;
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
          ),
        ),
      ],
    );
  }

  Future<Map<dynamic, dynamic>> getUsers(BoothController controller) async {
    Map<dynamic, dynamic> users = await controller.getNonBlockedUsers(controller.student.key);
    Map<String, String> userList = {};
    users.forEach((key, value) {
      try{
      if (!(value as Map).containsKey('name')) {
        return;
      }
      String name = value['name'] as String;
      String userKey = key as String;
      userList[userKey] = name;
      }
      catch (e){
        // Skip user
      }
    });
    return userList;
  }

  Future<Map<dynamic, dynamic>> getSessions(BoothController controller) async {
    Map<dynamic, dynamic> sessions = await controller.getNonBlockedSessions(controller.student.key);
    Map<String, String> sessionList = {};
    sessions.forEach((key, value) {
      try{
      if (!(value as Map).containsKey('title')) {
        return;
      }
      String name = value['title'] as String;
      String sessionKey = key as String;
      sessionList[sessionKey] = name;
      }
      catch (e) {
        // Skip
      }
    });
    return sessionList;
  }
}
