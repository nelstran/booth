import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/Database/SessionDatabase.dart';

import 'session_model.dart';
import 'student_model.dart';

/// Controller will act as a bridge from front end to back end.
/// Anything needed to modify the logged in user or sessions should
/// go through controller.
///
/// MAYBE NOT NEEDED I PROBABLY MADE THIS MORE COMPLICATED THAN
/// IT SHOULD BE
class BoothController {
  final DatabaseReference ref;
  SessionDatabase db;
  Map sessions = {};
  Student student;

  BoothController(
    this.ref,
  )   : db = SessionDatabase(ref),
        student = Student(uid: "", firstName: "", lastName: "") {
    // Modify session on change
    DatabaseReference sessionRef = ref.child('sessions');
    sessionRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;
      sessions = data as Map;
    });
  }

  /// Get logged in user's account information
  Future<String> fetchAccountInfo(User user) async {
    try {
      String key = await db.fetchUserKey(user);
      DatabaseReference studentRef = ref.child("users/$key");
      final snapshot = await studentRef.get();
      var value = snapshot.value as Map;

      // Modify student on change
      studentRef.onValue.listen((event) {
        setStudent(key, event.snapshot.value as Map);
      });

      setStudent(key, value);
      return student.fullname;
    } catch (error) {
      return "CANNOT FIND USER";
    }
  }

  /// Set student of the controller
  void setStudent(String key, Map value) {
    final fullname = value['name'].toString().split(" ");
    student = Student(
        key: key,
        uid: value['uid'],
        firstName: fullname.first,
        lastName: fullname.last);

    // Maybe have session key to know what session they're in if any???
    if (value.containsKey('sessionKey'))
      student.sessionKey = value['sessionKey'];
  }

  /// Add the given student to the database
  void addUser(Student student) {
    Map values = {"uid": student.uid, "name": student.fullname};
    db.addUser(values);
  }

  /// Given its key, remove the user from the database
  void removeUser(String key) {
    db.removeUser(key);
  }

  String? previousKey = "";

  /// Add the logged in user (student) to a session
  void addUserToSession(String sessionKey, Student user) async {
    Map studentValues = {
      "name": user.fullname,
      "uid": user.uid,
    };

    String? key = await db.addStudentToSession(sessionKey, studentValues);

    db.updateUser(user.key, {'sessionKey': key});
  }

  /// Remove the logged in user (student) from the session
  void removeUserFromSession(String sessionKey, String userKey) {
    db.removeStudentFromSession(sessionKey, userKey);
  }

  /// Add the session to the database, the user who made it
  /// automatically joins the session
  void addSession(Session session, Student owner) {
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
