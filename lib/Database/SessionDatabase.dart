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
  late String institution;
  SessionDatabase(this.ref);

  /// Get the key of logged in user's
  Future<String> fetchUserKey(User user) async {
    final newRef = ref.child("users");
    final event = await newRef.once();

    // Iterate through the list of users until we find a match (Probably will be slow af when there's a lot of users)
    for (final child in event.snapshot.children) {
      Map value = child.value as Map;
      if (value['uid'] == user.uid) {
        return child.key!;
      }
    }
    return Future.error('Error fetching user info');
  }

  /// Add user to database given a set of values
  Future<void> addUser(Map values) async {
    final newRef = ref.child('users').push();
    await newRef.set(values);
  }

  /// Change field values of existing user
  Future<void> updateUser(String key, Map<String, Object?> values) async {
    if (key == "") return;
    final newRef = ref.child("users/$key");
    await newRef.update(values);
  }

  /// Change field values of User's profile
  void updateProfile(String key, Map<String, Object?> values) async {
    if (key == "") return;
    final newRef = ref.child("users/$key/profile");
    await newRef.update(values);
  }

  /// Get user profile
  Future<Object?> getProfile(String key) async {
    final newRef = ref.child("users/$key/profile");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  /// Get user entry in database
  Future<Object?> getUser(String key) async {
    final newRef = ref.child("users/$key");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  Future<Object?> getSession(String key) async {
    final newRef = ref.child("institutions/$institution/sessions/$key");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  /// Remove user by its key
  void removeUser(String key) {
    if (key == "") return; //Prevent removing all students
    ref.child('users/$key').remove();
  }

  void setInstitution(String institute) {
    institution = institute;
  }

  /// Add a session and include the user who made it into that session
  Future<Map<String, String?>> addSession(
      Map sessionValues, Map studentValues) async {
    // Adding the session given a map
    final newRef = ref.child('institutions/$institution/sessions').push();
    await newRef.set(sessionValues);

    // Adding the user to the session we just made
    final userRef = newRef.child("users").push();
    await userRef.set(studentValues);

    return {"sessionKey": newRef.key, "userKey": userRef.key};
  }

  /// Change field values of existing session
  Future<void> updateSession(String key, Map<String, Object?> values) async {
    if (key == "") return;
    final newRef = ref.child("institutions/$institution/sessions/$key");
    await newRef.update(values);
  }

  /// Remove session by key
  Future<void> removeSession(String key) async {
    if (key == "") return; // Prevent removing all sessions
    await ref.child('institutions/$institution/sessions/$key').remove();
  }

  /// Add user to existing session
  Future<String?> addStudentToSession(String key, Map student) async {
    // Thinking about getting session by the given key and adding student values to 'users'
    final newRef =
        ref.child('institutions/$institution/sessions/$key/users').push();
    await newRef.set(student);
    return newRef.key;
  }

  /// Remove current user from existing session
  void removeStudentFromSession(String sessionKey, String studentKey) {
    if (sessionKey == "" || studentKey == "") return;

    ref
        .child(
            'institutions/$institution/sessions/$sessionKey/users/$studentKey')
        .remove();
  }

  // Gets all of the users recorded in the database
  Future<Object?> getAllUsers() async {
    final newRef = ref.child("users");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  /// Get all sessions from the given institution
  Future<Object?> getAllSessions([value]) async {
    value = value ?? institution;
    final newRef = ref.child("institutions/$institution/sessions");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  //----- FRIEND SYSTEM ---- //

  /// Get list friends by user key
  Future<Object?> getFriends(String key) async {
    if (key == '') return null;
    var event = await ref.child('users/$key/friends').once();
    return event.snapshot.value;
  }

  /// Remove 2 user's from their friends list
  void removeFriend(String studentKey, String friendKey) {
    if (studentKey == '' || friendKey == '') return;
    ref.child('users/$studentKey/friends/$friendKey').remove();
    ref.child('users/$friendKey/friends/$studentKey').remove();
  }

  /// Get list of friend requests
  Future<Object?> getRequests(String key) async {
    if (key == "") return null;
    final newRef = ref.child("users/$key/friends/requests");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  /// Send friend request to user given by their [receiverKey]
  void sendFriendRequest(String senderKey, String receiverKey) async {
    if (senderKey == '' || receiverKey == '') return;
    final senderRef = ref.child('users/$senderKey/friends/requests/outgoing');
    final receiverRef =
        ref.child('users/$receiverKey/friends/requests/incoming');
    await senderRef.update({receiverKey: ""});
    await receiverRef.update({senderKey: ""});
  }

  /// Decline a friend request, removing their entry in the requests list
  void declineFriendRequest(String studentKey, String strangerKey) async {
    if (studentKey == '' || strangerKey == '') return;
    await ref
        .child('users/$studentKey/friends/requests/incoming/$strangerKey')
        .remove();
    await ref
        .child('users/$strangerKey/friends/requests/outgoing/$studentKey')
        .remove();
  }

  /// Accept a friend request and remove users from the requests list
  void acceptFriendRequest(String studentKey, String friendKey) async {
    if (studentKey == '' || friendKey == '') return;
    final studentRef = ref.child('users/$studentKey/friends/');
    final friendRef = ref.child('users/$friendKey/friends/');
    studentRef.child('requests/incoming/$friendKey').remove();
    friendRef.child('requests/outgoing/$studentKey').remove();

    studentRef.child('requests/outgoing/$friendKey').remove();
    friendRef.child('requests/incoming/$studentKey').remove();

    await studentRef.update({friendKey: ""});
    await friendRef.update({studentKey: ""});
  }

  /// Given a user's database [key], grab their name
  Future<Object?> getNameByKey(String key) async {
    if (key == "") return null;
    final newRef = ref.child("users/$key/name");
    final event = await newRef.once();
    return event.snapshot.value ?? "";
  }

  /// Given an [institute] name, grab their entry from the database
  Future<Object?> getInstitute(String institute) async {
    final newRef = ref.child("institutions/$institute");
    final event = await newRef.once();
    return event.snapshot.value;
  }

  Future<void> createSampleSession(Map sample) async {
    final newRef = ref.child('institutions/$institution/sessions').push();
    await newRef.set(sample);
  }

  Future<Object?> getUid(
      String institution, String seshKey, String ownerKey) async {
    // Adjust the path to point exactly to the uid location
    final newRef = await ref
        .child("institutions/$institution/sessions/$seshKey/users/$ownerKey");
    final event = await newRef.once();
    return event.snapshot.value;
  }
}
