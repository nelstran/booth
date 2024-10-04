import 'package:flutter_application_1/MVC/analytics_extension.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/session_model.dart';
import 'package:flutter_application_1/MVC/student_model.dart';

extension SessionExtension on BoothController{

  /// Get all open session at the given school, if no school is given, search the user's assigned school
  Future<Map<dynamic, dynamic>> getSessions([institution]) async {
    institution = institution ?? studentInstitution;
    Object? json = await db.getAllSessions(institution);
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
}