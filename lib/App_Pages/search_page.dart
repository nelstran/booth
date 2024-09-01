import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  final String searchString;
  const SearchPage(
    this.searchString,
    {super.key}
    );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("RESULTS FOR: $searchString \n'Search for friends view UI' placeholder")
      ),
    );
  }
  
}