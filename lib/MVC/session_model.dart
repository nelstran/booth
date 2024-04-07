// import 'dart:ui';
import 'dart:math';

import 'package:flutter_application_1/MVC/student_model.dart';

class Session {
  String key; // Helpful for finding its location in the database
  // final List<Student> memberIds; // List of members in the session
  final String field;
  final int level;
  final String subject;

  final String title;
  final String description;
  final String time;
  final String locationDescription;
  final int seatsAvailable;
  final bool isPublic;
  int dist;
  int currNum;
  int maxNum;

  // Color color;

  Session({
    // required this.memberIds,
    required this.field,
    required this.level,
    required this.subject,
    required this.title,
    required this.description,
    required this.time,
    required this.locationDescription,
    required this.seatsAvailable,
    required this.isPublic,
    String? key,
    int? dist,
    int? currNum,
    int? maxNum,
  })  : key = key ?? "NaN",
        // dist = dist ?? 0,
        dist = dist ?? 10 + Random().nextInt(100 - 10 + 1),
        currNum = currNum ?? 1,
        maxNum = maxNum ?? 0;
  // color = colorLibrary.addField(field); // Group sessions by the Field they're in
  /// Converts the booth session to a JSON format
    Map<String, dynamic> toJson() {
      return {
        'title' : title,
        'description': description,
        'time': time,
        'locationDescription': locationDescription,
        'seatsAvailable': seatsAvailable,
        'subject': subject,
        'isPublic': isPublic,
        'field': field,
        'level': level,
        'key': key
      };
    }
}
