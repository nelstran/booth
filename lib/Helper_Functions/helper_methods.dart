import 'package:flutter/material.dart';

// Method to display messages to user
void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title: Text(message),

    ),
  );
}

