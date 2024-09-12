import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Image.asset(
                'assets/images/map.png'),
    );
    
    // return const Text("Map Placeholder");
  }
}