import 'package:flutter/material.dart';

class SearchPage extends SearchDelegate<String> {
  // Mock data, need this to be a list of users from the database
  final List<String> searchList = [
    "Brayden", "Bob", "Nelson", "Noah", "Jack", "Joel", "Leena", "Laura"
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
    final List<String> searchResults = searchList
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
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestionList = query.isEmpty
      ? []
      : searchList
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();

  return ListView.builder(
    itemCount: suggestionList.length,
    itemBuilder: (context, index) {
      return ListTile(
        trailing: Icon(Icons.add),
        title: Text(suggestionList[index]),
        onTap: () {
          query = suggestionList[index];
          // Show the search results based on the selected suggestion.
        },
      );
    },
  );
  }
}


