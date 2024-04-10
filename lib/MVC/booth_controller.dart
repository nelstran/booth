import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/Database/SessionDatabase.dart';

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
    // student = Student(
    //   key: key,
    //   uid: value['uid'],
    //   firstName: fullname.first,
    //   lastName: fullname.last
    // );
  }

  /// Add the given student to the database
  void addUser(Student student) {
    db.addUser(student.toJson());
  }

  /// Given its key, remove the user from the database
  void removeUser(String key) {
    db.removeUser(key);
  }

  String? previousKey = "";

  /// Add the logged in user (student) to a session
  void addUserToSession(String sessionKey, Student user) async {
    // If user is in a session, remove them from it before adding them to a new one
    if(user.session != "") removeUserFromSession(user.session, user.sessionKey);
    Map studentValues = {
      "name": user.fullname,
      "uid": user.uid,
    };

    String? key = await db.addStudentToSession(sessionKey, studentValues);
    db.updateUser(user.key, {'session': sessionKey, 'sessionKey': key});
  }

  /// Remove the logged in user (student) from the session
  void removeUserFromSession(String sessionKey, String userSessionKey) {
    db.removeStudentFromSession(sessionKey, userSessionKey);
  }

  /// Add the session to the database, the user who made it
  /// automatically joins the session
  void addSession(Session session, Student owner) {
    // We just want name and uid instead all of its fields
    Map studentValues = { 
      "name": owner.fullname,
      "uid": owner.uid,
    };
    db.addSession(session.toJson(), studentValues);
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
