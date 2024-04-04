class Student{
  final String key; // Helpful for finding its location in the database
  final String uid;
  final String firstName;
  final String lastName;
  final String _fullname;
  String get fullname => _fullname;

  Student(
    this.key, 
    this.uid,
    this.firstName,
    this.lastName
  ):
  _fullname = "$firstName $lastName";
}