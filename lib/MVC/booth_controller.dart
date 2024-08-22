import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Database/SessionDatabase.dart';
import 'package:logger/web.dart';

import 'session_model.dart';
import 'student_model.dart';

/// Controller will act as a bridge from front end to back end.
/// Anything needed to modify the logged in user or sessions should
/// go through controller.
class BoothController {
  final DatabaseReference ref;
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
      var value = snapshot.value as Map;
      value['key'] = snapshot.key;
      // Modify student on change
      studentRef.onValue.listen((event) {
        var value = event.snapshot.value as Map;
        value['key'] = event.snapshot.key;

        setStudent(key, value);
      });

      setStudent(key, value);
      return student.fullname;
    } catch (error) {
      return "CANNOT FIND USER";
    }
  }

  /// Set student of the controller
  void setStudent(String key, Map value) {
    student = Student.fromJson(value);
  }

  /// Add the given student to the database
  void addUser(Student student) {
    db.addUser(student.toJson());
  }

  /// Given its key, remove the user from the database
  void removeUser(String key) {
    db.removeUser(key);
  }

  void updateUserProfile(String key, Map<String, Object?> value) {
    db.updateProfile(key, value);
  }

  String? previousKey = "";

  /// Add the logged in user (student) to a session
  void addUserToSession(String sessionKey, Student user) async {
    // If user is in a session, remove them from it before adding them to a new one
    if (user.session != "") {
      removeUserFromSession(user.session, user.sessionKey);
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
  void removeUserFromSession(String sessionKey, String userSessionKey) {
    db.removeStudentFromSession(sessionKey, userSessionKey);
    db.updateUser(
        student.key, {"session": "", "sessionKey": "", "ownedSessionKey": ""});
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
    db.updateUser(
        owner.key, {"ownedSessionKey": sessionKey, "session": sessionKey});

    // Update session in db to state who owns that session
    db.updateSession(keys["sessionKey"]!, {"ownerKey": userKey});
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
}

///  Deletes the User account in FireBase
Future<void> deleteUserAccountFB(BuildContext context) async {
  // Logs Exceptions
  var logger = Logger();
  // Checks if context is mounted so no crash happens
  //if (!context.mounted) return;
  try {
    // This Deletes the user from Firebase
    await FirebaseAuth.instance.currentUser!.delete();
    Navigator.of(context).pop();
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
  try {
    String email = FirebaseAuth.instance.currentUser!.email!;
    // Runs helper function to get the password
    String password = await getPassword(context);
    // Get the Users credential from Username and Password
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);
    await FirebaseAuth.instance.currentUser!
        .reauthenticateWithCredential(credential);
    // After fresh credential is gained, Firebase Deletes the account
    await FirebaseAuth.instance.currentUser!.delete();
    Navigator.of(context).pop();
  } on FirebaseAuthException catch (e) {
    logger.e(e);
    // Handles Firebase exceptions during reauthentication
    if (e.code == "wrong-password") {
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
              content: const Text("Wrong Password. Try Again."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Ok"),
                )
              ],
            );
          });
      // Handle case where the entered password is incorrect
    } else if (e.code == "user-mismatch") {
      // Handle case where the user doesn't match
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
              content: const Text("User Mis-Match Error. Please Try Again."),
              actions: [
                TextButton(
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
              content: const Text("Error Occured, Please Try Again."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Ok"),
                )
              ],
            );
          });
    }
  } catch (e) {
    logger.e(e);
  }
}

/// Dialog Pops up to ask the user for their password. If they get it wrong,
/// asks to try again until they get it.
Future<String> getPassword(BuildContext context) async {
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
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              password = passwordController.text;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );

  return password;
}
