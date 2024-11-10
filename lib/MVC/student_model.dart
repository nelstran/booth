class Student {
  late final String uid; // Account Identifier
  late final String key; // User key in database

  late final String firstName;
  late final String lastName;
  late final String _fullname;
  String get fullname => _fullname;

  /// Key of session they're in
  late String session; 
  /// User's key in the session
  late String sessionKey; 
  /// Key of session they own
  late String ownedSessionKey; 

  // Constructor
  Student({
    required this.uid,
    required this.firstName,
    required this.lastName,
    String? key,
    String? ownedSessionKey
  })  : key = key ?? "",
        ownedSessionKey = ownedSessionKey ?? "",
        _fullname = "$firstName $lastName",
        session = "",
        sessionKey = "";

  // Json Constructor
  Student.fromJson(Map json) {
    List<String> name = (json['name'] ?? "").toString().split(" ");

    key = json['key'] ?? "";
    uid = json['uid'] ?? "";

    firstName = name.first;
    lastName = name.last;
    _fullname = json['name'];

    if (json.containsKey('session')) session = json['session'];
    if (json.containsKey('sessionKey')) sessionKey = json['sessionKey'];
    if (json.containsKey('ownedSessionKey')) {
      ownedSessionKey = json['ownedSessionKey'];
    }
  }

  /// Converts the student to a JSON format
  Map<String, dynamic> toJson() {
    return {
      // "key": key,
      "session": session,
      "sessionKey": sessionKey,
      "ownedSessionKey": ownedSessionKey,
      "uid": uid,
      "name": fullname
    };
  }
}
