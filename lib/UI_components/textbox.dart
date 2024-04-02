import 'package:flutter/material.dart';

/// This class is the blueprint for a textbox object
class TextBox extends StatelessWidget {
  // These are the instance variables of a textbox object

  // The text displayed before typing into the textbox
  final String hintText;

  // This is set to true when a password is typed (hides the password with dots)
  final bool obscureText;

  // This controller accesses whatever is typed into the text box
  final TextEditingController controller;

 
  const TextBox({
    // When creating a textbox, these are required fields to be set
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          // Round the corners of the textbox
          borderRadius: BorderRadius.circular(12)
        ),
        hintText: hintText
      ),
      obscureText: obscureText,
    );
  }
}