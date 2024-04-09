/* This database stores the booth sessions that users have created
*  In firebase, we will have a collection called "Sessions" that stores each session.
*  Each session has the following details:
* - Location
* - Subject
* - Seats Available
* - End Time
* - Etc.
*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Trying out map to pass values to database, thinking it will make it easier
// to modify fields from each class
class SessionDatabase {
  final DatabaseReference ref;

  SessionDatabase(this.ref);

  /// Add user to database given a set of values
  void addUser(Map values) {
    final newRef = ref.child('users').push();
    newRef.set(values);
    // newRef.set({
    //   "name": student.fullname
    //   // More values to be added later
    // });
  }

  /// Change field values of existing user
  void updateUser(String key, Map<String, Object?> values) async {
    if (key == "") return;
    final newRef = ref.child("users/$key");
    await newRef.update(values);
  }

  /// Remove user by its key
  void removeUser(String key) {
    if (key == "") return; //Prevent removing all students
    ref.child('users/$key').remove();
  }

  /// Add a session and include the user who made it into that session
  void addSession(Map sessionValues, Map studentValues) async {
    // Adding the session given a map
    final newRef = ref.child('sessions').push();
    await newRef.set(sessionValues);

    // Adding the user to the session we just made
    final userRef = newRef.child("users").push();
    await userRef.set(studentValues);
  }

  /// Change field values of existing session
  void updateSession(String key, Map<String, Object?> values) async {
    if (key == "") return;
    final newRef = ref.child("sessions/$key");
    await newRef.update(values);
  }

  /// Remove session by key
  void removeSession(String key) {
    if (key == "") return; // Prevent removing all sessions
    ref.child('sessions/$key').remove();
  }

  /// Add user to existing session
  Future<String?> addStudentToSession(String key, Map student) async {
    // Thinking about getting session by the given key and adding student values to 'users'
    final newRef = ref.child('sessions/$key/users').push();
    await newRef.set(student);
    return newRef.key;
  }

  /// Remove current user from existing session
  void removeStudentFromSession(String sessionKey, String studentKey) {
    if (sessionKey == "" || studentKey == "") return;

    ref.child('sessions/$sessionKey/users/$studentKey').remove();
  }

  /// Get the key of logged in user's
  Future<String> fetchUserKey(User user) async {
    final newRef = ref.child("users");
    final event = await newRef.once(DatabaseEventType.value);

    // Iterate through the list of users until we find a match (Probably will be slow af when there's a lot of users)
    for (final child in event.snapshot.children) {
      Map value = child.value as Map;
      if (value['uid'] == user.uid) {
        return child.key!;
      }
    }
    return Future.error('Error fetching user info');
  }

  isUserInSession(String uid) {}
}
