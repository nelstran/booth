import 'package:flutter/material.dart';

/// This class is the blueprint for a button object
class Button extends StatelessWidget {
  // These are the instance variables of a button object
  final String text;

  // Function for what happens when the button is pressed
  final void Function()? onTap;

  const Button({
    // When creating a button, these are required fields to be set
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          // Round the corners of the button
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      
    );
  }

}