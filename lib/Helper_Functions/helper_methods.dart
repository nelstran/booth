import 'package:flutter/material.dart';

// Method to display messages to user
void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title: const Text("Uh oh! Something went wrong!"),
      content: Text(message),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: const Text("OK"),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],

    ),
  );
}

