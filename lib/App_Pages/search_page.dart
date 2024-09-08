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
    return FutureBuilder<List<String>>(
      future: getUserNames(controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Users'));
        }

        final List<String> searchResults = snapshot.data!
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
    return FutureBuilder<List<String>>(
      future: getUserNames(controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        }

        final List<String> suggestionList = query.isEmpty
            ? []
            : snapshot.data!
                .where(
                    (item) => item.toLowerCase().contains(query.toLowerCase()))
                .toList();

        return ListView.builder(
          itemCount: suggestionList.length,
          itemBuilder: (context, index) {
            return ListTile(
              trailing: const Icon(Icons.add),
              title: Text(suggestionList[index]),
              onTap: () {
                // Change Later to show the users profile/session examples
                query = suggestionList[index];
                // Show the search results based on the selected suggestion.
              },
            );
          },
        );
      },
    );
  }

  Future<List<String>> getUserNames(BoothController controller) async {
    Map<dynamic, dynamic> users =
        await controller.getUsers(); // Await the Future

    List<String> userList = [];

    users.forEach((key, value) {
      String name = value['name'];
      userList.add(name);
    });

    return userList;
  }
}
