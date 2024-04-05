class Student{
  String key; // Helpful for finding its location in the user database
  // String sessionKey; // Could be use for finding its location in the session database
  final String uid;
  final String firstName;
  final String lastName;
  final String _fullname;
  String get fullname => _fullname;

  Student({
    required this.uid,
    required this.firstName,
    required this.lastName,
    String? key,
  }
  ):
  key = key ?? "NaN",
  _fullname = "$firstName $lastName";
  // sessionKey = "";
}