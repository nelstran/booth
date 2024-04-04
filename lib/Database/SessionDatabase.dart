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


// Trying out map to pass values to database, thinking it will be easier for now
// so in case we want to add/remove fields from each class
class SessionDatabase{
  final DatabaseReference ref;

  SessionDatabase(this.ref);

  void addUser(Map values) {
    final newRef = ref.child('users').push();
    newRef.set(values);
    // newRef.set({
    //   "name": student.fullname
    //   // More values to be added later
    // });
  }

  void updateUser(Map values){
    // NOT YET IMPLEMENTED
  }

  void removeUser(String key){
    ref.child('users/$key').remove();
  }

  void addSession(Map sessionValues, Map studentValues) {
    final newRef = ref.child('sessions').push();

    newRef.set(sessionValues);
    // newRef.set({
    //   "owner": student.fullname,
    //   "field": session.field,
    //   "level": session.level,
    //   "topic": session.topic,
    //   "currNum": session.currNum,
    //   "maxNum": session.maxNum,
    //   "users": []
    //   // More values to be added later
    // });

    final userRef = newRef.child("users").push();
    userRef.set(studentValues);
    // userRef.set({
    //   "name": student.fullname,
    //   "uid": student.uid
    // });
  }

  void updateSession(String key, Map values){
    // NOT YET IMPLEMENTED
  }

  void removeSession(String key){
    ref.child('sessions/$key').remove();
  }

  void addStudentToSession(String key, Map values){
    final newRef = ref.child("sessions/$key/users").push();
    newRef.set(values);
  }

  void removeStudentFromSession(String sessionKey, String studentKey){
    ref.child('sessions/$sessionKey/users/$studentKey').remove();
  }

  Future<Map> fetchUser(User user) async {
    final newRef = ref.child("users");
    final event = await newRef.once(DatabaseEventType.value);
    for (final child in event.snapshot.children){
      Map value = child.value as Map;
      if(value['uid'] == user.uid){
        var username = (value['name'] as String).split(" ");
        Map student = {
          "key": child.key,
          "uid": user.uid,
          "fname": username.first,
          "lname": username.last
        };
        return student;
      }
    }
    return Future.error('Error fetching user info');
  }

  
  // TODO:
  // get the current logged in user
  // get collection of all sessions from firebase - don
  // write a session to firebase - done
  // read sessions from firebase - done
}