/* This database stores the booth sessions that users have created
*  In firebase, we will have a collection called "Sessions" that stores each session.
*  Each session has the following details:
* - Location
* - Subject
* - Seats Available
* - End Time
* - Etc.
*/
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/MVVM/session_model.dart';
import 'package:flutter_application_1/MVVM/student_model.dart';

class SessionDatabase{
  final DatabaseReference ref;

  SessionDatabase({
    required this.ref
  });

  void addStudent(Student student) {
    final newRef = ref.child('users').push();
    newRef.set({
      "name": student.fullname
      // More values to be added later
    });
  }

  void removeStudent(Student student){
    ref.child('users/${student.key}').remove();
  }

  void addSession(Session session, Student student) {
    final newRef = ref.child('sessions').push();
    newRef.set({
      "owner": student.fullname,
      "field": session.field,
      "level": session.level,
      "topic": session.topic,
      "currNum": session.currNum,
      "maxNum": session.maxNum,
      "users": []
      // More values to be added later
    });

    final userRef = newRef.child("users").push();
    userRef.set({
      "name": student.fullname,
      "uid": student.uid
    });
  }

  void removeSession(Session session){
    ref.child('sessions/${session.key}').remove();
  }

  
  // TODO:
  // get the current logged in user
  // get collection of all sessions from firebase
  // write a session to firebase
  // read sessions from firebase
}