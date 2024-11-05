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
  late int seatsTaken;

  double? latitude;
  double? longitude;
  String? address;

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
    this.latitude,
    this.longitude,
    this.address,
  })  : key = key ?? "NaN",
        seatsTaken = 1,
        ownerKey = "";

  /// Json Constructor (Maybe not required/used)
  Session.fromJson(Map json) {
    field = json['field'] ?? "N/A";
    level = json['level'] ?? "N/A";
    subject = json['subject'] ?? "N/A";
    title = json['title'] ?? "N/A";
    description = json['description'] ?? "N/A";
    time = json['time'] ?? "N/A";
    locationDescription = json['locationDescription'] ?? "N/A";
    seatsAvailable = json.containsKey('seatsAvailable') ? json['seatsAvailable'] : 0;
    isPublic = json['isPublic'] ?? "N/A";
    // seatsTaken = (json['users'] as Map).length;
    if (json.containsKey('users')) seatsTaken = (json['users'] as Map).length;
    if (json.containsKey('ownerKey')) ownerKey = json['ownerKey'];

    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
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
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
