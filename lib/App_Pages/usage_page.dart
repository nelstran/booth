import 'package:flutter/material.dart';

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
     return Expanded(
      child: Image.asset(
                'assets/images/usage.png'),
    );
    // return const Text("Usage Placeholder");
  }
}