import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/Database/SessionDatabase.dart';

import 'session_model.dart';
import 'student_model.dart';


// Controller will handle all classes and pass its values to the 
// appropriate destination.
class BoothController{
  final DatabaseReference ref;
  SessionDatabase db;

  BoothController(
    this.ref,
  ):
  db = SessionDatabase(ref);

  Future<Student?> fetchAccountInfo(User user) async {
    try{
      Map values = await db.fetchUser(user);
      return Student(
      values['key'],
      values['uid'], 
      values['fname'],
      values['lname']
      );
    }catch(error){
      return null;
    }
  }
  
  void addUser(Student student){
    Map values = {
      "name": student.fullname
    };
    db.addUser(values);
  }

  void removeUser(Student student){
    db.removeUser(student.key);
  }

  void addUserToSession(Session session, Student student){
    Map values = {
      "name": student.fullname,
      "uid": student.uid
    };
    session.addStudent(student.fullname, student.uid);
    db.updateSession(session.key, values);
  }

  void removeUserToSession(Session session, Student student){
    db.removeStudentFromSession(session.key, student.key);
  }

  void addSession(Session session, Student owner){
    Map sessionValues = {
      "field": session.field,
      "level": session.level,
      "topic": session.topic,
      "currNum": session.currNum,
      "maxNum": session.maxNum
    };

    Map studentValues = {
      "name": owner.fullname,
      "uid": owner.uid,
    };
    db.addSession(sessionValues, studentValues);
  }

  void removeSession(Session session){
    db.removeSession(session.key);
  }
}