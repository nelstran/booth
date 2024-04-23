// import 'dart:ui';
import 'dart:math';

class Session {
  late String key; // Session key in database

  late final String field;
  late final int level;
  late final String subject;

  late final String title;
  late final String description;
  late final String time;
  late final String locationDescription;
  late final int seatsAvailable;
  late final bool isPublic;
  late int dist;
  late int seatsTaken;

  late String ownerKey; // User key of the session owner

  /// Constructor
  Session({
    String? key,
    required this.field,
    required this.level,
    required this.subject,
    required this.title,
    required this.description,
    required this.time,
    required this.locationDescription,
    required this.seatsAvailable,
    required this.isPublic,
  })  : key = key ?? "NaN",
        dist = 10 + Random().nextInt(100 - 10 + 1), //Random for now
        seatsTaken = 1,
        ownerKey = "";

  /// Json Constructor (Maybe not required/used)
  Session.fromJson(Map json) {
    field = json['field'];
    level = json['level'];
    subject = json['subject'];
    title = json['title'];
    description = json['description'];
    time = json['time'];
    locationDescription = json['locationDescription'];
    seatsAvailable = json['seatsAvailable'];
    isPublic = json['isPublic'];
    dist = 10 + Random().nextInt(100 - 10 + 1);
    seatsTaken = (json['users'] as Map).length;
    if (json.containsKey('ownerKey')) ownerKey = json['ownerKey'];
  }

  /// Converts the booth session to a JSON format
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'time': time,
      'locationDescription': locationDescription,
      'seatsAvailable': seatsAvailable,
      'subject': subject,
      'isPublic': isPublic,
      'field': field,
      'level': level,
      'key': key,
      'ownerKey': ownerKey,
    };
  }
}
