import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Database/SessionDatabase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/web.dart';

import '../Database/firestore_database.dart';
import 'session_model.dart';
import 'student_model.dart';

import 'package:intl/intl.dart';

/// Controller will act as a bridge from front end to back end.
/// Anything needed to modify the logged in user or sessions should
/// go through controller.
class BoothController {
  final DatabaseReference ref;
  final FirestoreDatabase firestoreDb = FirestoreDatabase();
  SessionDatabase db;
  Student student;

  // Constructor
  BoothController(
    this.ref,
  )   : db = SessionDatabase(ref),
        student = Student(uid: "", firstName: "", lastName: "");

  /// Get logged in user's account information
  Future<String> fetchAccountInfo(User user) async {
    try {
      String key = await db.fetchUserKey(user);
      DatabaseReference studentRef = ref.child("users/$key");
      final snapshot = await studentRef.get();
      final doc = await firestoreDb.getUserData(user.uid);
      if (doc == null) {
        firestoreDb.addUserData(user.uid);
      }
      var value = snapshot.value as Map;
      value['key'] = snapshot.key;
      // Modify student on change
      studentRef.onValue.listen((event) {
        // In an event the user deletes their account
        if (!event.snapshot.exists) {
          return;
        }
        var value = event.snapshot.value as Map;
        value['key'] = event.snapshot.key;

        setStudent(key, value);
      });

      setStudent(key, value);
      return student.fullname;
    } catch (error) {
      return Future.error(error);
    }
  }

  ///  Deletes the User account in FireBase
  Future<void> deleteUserAccountFB(BuildContext context) async {
    // Logs Exceptions
    var logger = Logger();
    // Checks if context is mounted so no crash happens
    //if (!context.mounted) return;
    try {
      // This Deletes the user from Firebase
      return reauthenticateThenDelete(context);
      //await FirebaseAuth.instance.currentUser!.delete();
      //Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      logger.e(e);
      // This means that Firebase wants them to re-authenticate before Axing the account
      if (e.code == "requires-recent-login") {
        print("Requires Recent login.");

        return reauthenticateThenDelete(context);
      } else {
        logger.e(e);
      }
    } catch (e) {
      logger.e(e);
    }
  }

  /// Function that Requires the user to input their password so they
  /// can prove that it is them with the account.
  Future<void> reauthenticateThenDelete(BuildContext context) async {
    // Used for Logging exceptions
    Logger logger = Logger();
    // Checks if context is mounted so no crash happens
    //if (!context.mounted) return;

    // Runs method to delete account
    //await tryToDelete(context);
    // For inputted password
    TextEditingController passwordController = TextEditingController();
    String password = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Password"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                //password = "Cancel";
                Navigator.of(context).pop();
                return;
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                password = passwordController.text;
                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                      email: FirebaseAuth.instance.currentUser!.email!,
                      password: password);
                  await FirebaseAuth.instance.currentUser!
                      .reauthenticateWithCredential(credential);
                  // After fresh credential is gained, Firebase Deletes the account
                  await FirebaseAuth.instance.currentUser!.delete();
                  //Pops both Dialogs (Enter Password + Warning Dialog)
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // Deletes the user from everywhere on our app
                  deleteUserAccountEverywhere(student);
                } on FirebaseAuthException catch (e) {
                  logger.e(e);
                  // Handles Firebase exceptions during reauthentication
                  if (e.code == "invalid-credential") {
                    showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("Wrong Password!"),
                                ),
                              ],
                            ),
                            content: const Text("Wrong Password. Try Again."),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Ok"),
                              )
                            ],
                          );
                        });
                    // Handle case where the entered password is incorrect
                  } else if (e.code == "wrong-password") {
                    // Handle case where the user doesn't match
                    showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("Wrong Password!"),
                                ),
                              ],
                            ),
                            content:
                                const Text("Wrong Password! Please Try Again."),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Ok"),
                              )
                            ],
                          );
                        });
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("error_occured"),
                                ),
                              ],
                            ),
                            content:
                                const Text("Error Occured, Please Try Again."),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Ok"),
                              )
                            ],
                          );
                        });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// THIS SHOULD EVENTUALLY GO IN THE PROFILE PAGE
  /// Deletes the user everywhere in our app;
  /// - Any Sessions they are apart of
  /// - Any Sessions that they currently own
  /// - The list of users that are recorded in the DB
  /// - From any Friends list they are apart of
  Future<void> deleteUserAccountEverywhere(Student student) async {
    // First Check to see if the user is apart of any study sessions
    // If so, remove from study session
    if (student.session != "") {
      await removeUserFromSession(student.session, student.sessionKey);
    }
    // Check is their are any sessions that they OWN and remove the session
    if (student.ownedSessionKey != "") {
      await removeUserFromSession(student.session, student.sessionKey);
      removeSession(student.ownedSessionKey);
    }

    Map<dynamic, dynamic> allFriends = await getFriendsKeys();

    for (var entry in allFriends.entries) {
      var key = entry.key;
      removeFriend(key);
    }

    // Then, remove from the "users" list in the Database
    removeUser(student.key);
  }

  /// Set student of the controller
  void setStudent(String key, Map value) {
    student = Student.fromJson(value);
  }

  /// Add the given student to the database
  void addUser(Student student) {
    db.addUser(student.toJson());
    firestoreDb.addUserData(student.uid);
  }

  /// Given its key, remove the user from the database
  void removeUser(String key) {
    db.removeUser(key);
  }

  /// Update the current user's profile
  void updateUserProfile(Map<String, Object?> value) {
    db.updateProfile(student.key, value);
  }

  Future<Map<dynamic, dynamic>> getUserProfile([key]) async {
    String studentKey;
    if (key != null) {
      studentKey = key;
    } else {
      studentKey = student.key;
    }
    Object? json = await db.getProfile(studentKey);
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  /// Add the logged in user (student) to a session
  Future<void> addUserToSession(String sessionKey, Student user) async {
    // If user is in a session, remove them from it before adding them to a new one
    if (user.session != "") {
      await removeUserFromSession(user.session, user.sessionKey);
    }

    Map studentValues = {
      "name": user.fullname,
      "uid": user.uid,
    };

    String? key = await db.addStudentToSession(sessionKey, studentValues);
    db.updateUser(user.key, {'session': sessionKey, 'sessionKey': key});
    // Check to see if user has a session that they own
    // if (user.session != user.ownedSessionKey) {
    //   db.removeSession(user.ownedSessionKey);
    // }
  }

  /// Remove the logged in user (student) from the session
  Future<void> removeUserFromSession(
      String sessionKey, String userSessionKey) async {
    db.removeStudentFromSession(sessionKey, userSessionKey);
    db.updateUser(
        student.key, {"session": "", "sessionKey": "", "ownedSessionKey": ""});
    await endSessionLogging(student.uid);
  }

  /// Add the session to the database, the user who made it
  /// automatically joins the session
  void addSession(Session session, Student owner) async {
    // We just want name and uid instead all of its fields
    Map studentValues = {
      "name": owner.fullname,
      "uid": owner.uid,
    };

    // Map sessionValues = {
    //   "field": session.field,
    //   "level": session.level,
    //   "subject": session.subject,
    //   "title": session.title,
    //   "description": session.description,
    //   "time": session.time,
    //   "locationDescription": session.locationDescription,
    //   "seatsAvailable": session.seatsAvailable,
    //   "isPublic": session.isPublic,
    //   "ownerKey": owner.key,
    // };
    Map<String, String?> keys =
        await db.addSession(session.toJson(), studentValues);
    String sessionKey = keys["sessionKey"]!;
    String userKey = keys["userKey"]!;

    // Set session the user owns
    student.ownedSessionKey = sessionKey;
    //Sets the owner's session key to the session key in the database
    db.updateUser(owner.key, {
      "session": sessionKey,
      "sessionKey": userKey,
      "ownedSessionKey": sessionKey,
    });

    // Update session in db to state who owns that session
    db.updateSession(sessionKey, {"ownerKey": userKey});
    startSessionLogging(owner.uid, session);
  }

  /// Given a key, remove the session from the database
  void removeSession(String key) {
    db.removeSession(key);
  }

  Future<bool> isUserAlreadyInSession(String uid) async {
    // Query the sessions node to find if the user is a member of any session

    bool inSession = await db.isUserInSession(uid);
    // Check if the snapshot has any data
    if (inSession == true) {
      // User is already in a session
      return true;
    } else {
      // User is not in any session
      return false;
    }
  }

  Future<Map<dynamic, dynamic>> getUsers() async {
    Object? json = await db.getAllUsers();
    if (json == null) {
      return {};
    }
    return json as Map<dynamic, dynamic>;
  }

  //----- FRIEND SYSTEM ---- //
  Future<Map<dynamic, dynamic>> getFriends() async {
    Object? json = await db.getFriends(student.key);
    if (json == null) {
      return {};
    }
    Map<dynamic, dynamic> friends = json as Map<dynamic, dynamic>;

    if (friends.containsKey('requests')) {
      friends.remove('requests');
    }

    for (var key in friends.keys) {
      // Get names for now, maybe get the entire student model later
      String value = await db.getNameByKey(key) as String;
      if (value == "") continue;
      friends[key] = value;
    }
    friends.removeWhere((key, value) => value == "");
    return friends;
  }

  Future<Map<dynamic, dynamic>> getFriendsKeys() async {
    Object? json = await db.getFriends(student.key);
    if (json == null) {
      return {};
    }
    Map<dynamic, dynamic> friendsKeys = json as Map<dynamic, dynamic>;

    if (friendsKeys.containsKey('requests')) {
      friendsKeys.remove('requests');
    }

    for (var key in friendsKeys.keys) {
      friendsKeys[key] = key;
    }
    return friendsKeys;
  }

  void removeFriend(String key) {
    db.removeFriend(student.key, key);
  }

  Future<Map<dynamic, dynamic>> getRequests(bool isOutgoing) async {
    Object? json = await db.getRequests(student.key);
    String outgoing = isOutgoing ? "outgoing" : "incoming";
    if (json == null || (json as Map)[outgoing] == null) {
      return {};
    }
    Map<dynamic, dynamic> requests = {};
    for (var key in json[outgoing].keys) {
      // Get names for now, maybe get the entire student model later
      String value = await db.getNameByKey(key) as String;
      if (value == "") continue;
      requests[key] = value;
    }
    requests.removeWhere((key, value) => value == "");
    return requests;
  }

  void sendFriendRequest(String key) async {
    Map<dynamic, dynamic> requests = await getRequests(true);
    Map<dynamic, dynamic> friends = await getFriends();
    if (requests.containsKey(key))
      return; // Do nothing if user already sent a request
    if (friends.containsKey(key))
      return; // Do nothing if user is already friends

    db.sendFriendRequest(student.key, key);
  }

  Future<void> declineFriendRequest(String key) async {
    return db.declineFriendRequest(student.key, key);
  }

  Future<void> acceptFriendRequest(String key) async {
    Map<dynamic, dynamic> requests = await getRequests(true);
    Map<dynamic, dynamic> friends = await getFriends();
    if (requests.containsKey(key)) {
      return; // Do nothing if user already sent a request
    }
    if (friends.containsKey(key)) {
      return; // Do nothing if user is already friends
    }
    return db.acceptFriendRequest(student.key, key);
  }

  // ---- USER ANALYTICS ---- //
  /// Creates an entry in the Firestore that stores what subject the user
  /// is studying and what location it is at while also taking note of the time they started.
  void startSessionLogging(String userKey, Session session) {
    var format = DateTimeFormat.dateAndTime;
    var timestamp = Timestamp.now().toDate();
    var todayInDays =
        timestamp.difference(DateTime(timestamp.year, 1, 1, 0, 0)).inDays;
    Map<String, dynamic> valuesToLog = {
      "start_timestamp": format(timestamp),
      "month": DateFormat.MMMM().format(timestamp),
      "day_of_month": DateFormat.d().format(timestamp),
      "day_of_week": DateFormat.EEEE().format(timestamp),
      "day_of_year": todayInDays.toString(),
      "subject": session.subject,
      "location_desc": session.locationDescription
    };

    firestoreDb.startSessionLogging(userKey, valuesToLog);
  }

  /// Grabs the starting log from Firestore and finalize the data for analytics.
  /// The data in curr_session should be in its own respective document containing data
  /// for easy querying.
  Future<void> endSessionLogging(String userKey) async {
    var doc = await firestoreDb.endSessionLogging(userKey);
    if (doc == null) {
      return;
    }

    var format = DateTimeFormat.dateAndTime;
    var endTime = Timestamp.now();
    var timestamp = format(endTime.toDate());
    var filename = endTime.millisecondsSinceEpoch.toString();
    doc['end_timestamp'] = timestamp;

    // Logs subject and time in seconds
    await firestoreDb.logSession(userKey, doc, filename);
  }

  Future<Map<String, dynamic>> fetchUserStudyData(String userKey) async {
    final doc = await firestoreDb.fetchuserStudyData(userKey);
    if (doc == null || doc.isEmpty) {
      return {};
    }
    doc.remove('curr_session');
    return doc;
  }

  // ---- Upload a Profile Picture ---- //

  Future<void> deleteProfilePictureStorage(String userKey) async {
    await firestoreDb.deleteProfilePictureStorage(userKey);
  }
  
  Future<Map<String, String>> uploadProfilePictureStorage(XFile file) async {
    final ref = await firestoreDb.uploadProfilePictureStorage(file);
    String url = await ref.getDownloadURL();
    String filepath = ref.fullPath;
    return {"url": url, "filepath": filepath};
  }

  Future<void> uploadProfilePictureFireStore(
      Map<String, String> pfpStorage, String userKey) async {
    await deleteProfilePictureStorage(userKey);  
    await firestoreDb.uploadProfilePictureFireStore(pfpStorage, userKey);
  }

  Future<String?> retrieveProfilePicture(String userKey) async {
    return await firestoreDb.retrieveProfilePicture(userKey);
  }
}
