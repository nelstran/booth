import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDatabase {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  FirestoreDatabase();

  void addUserData(String key) {
    db.collection("users").doc(key).set({});
  }
  
  Future<Map<String, dynamic>?> getUserData(String key) async {
    final ref = db.collection("users").doc(key);
    
    try{
      final doc = await ref.get();
      return doc.data();
    }
    catch(error){
      return Future.error(error);
    }
  }

  /// Gather data of session the user joins to start logging
  void startSessionLogging(String userKey, Map<String, dynamic> valuesToLog) {
    // Equivalent to 'users/{userKey}/session_logs/curr_session
    final ref = db.collection("users").doc(userKey).collection("session_logs").doc("curr_session");
    ref.set(valuesToLog);
  }
  
  /// Clear the curr_session document in Firebase for the given user 
  Future<Map<String, dynamic>?> endSessionLogging(String userKey) async {
    final ref = db.collection("users").doc(userKey).collection("session_logs").doc("curr_session");
    
    try{
      final doc = await ref.get();
      ref.set({});
      return doc.data();
    }
    catch(error){
      return Future.error(error);
    }
  }

  /// Logs the time the user spends studying the given subject
  Future<void> logSubjectTime(String userKey, String subject, int duration) async {
    // Retrieve subject logs
    final ref = db.collection("users").doc(userKey).collection("session_logs").doc("subject_data");
    logDurationHelper(ref, userKey, subject, duration);
  }

  /// Logs the time the user spends at the given location
  Future<void> logLocationTime(String userKey, String location, int duration) async  {
     // Retrieve location logs
    final ref = db.collection("users").doc(userKey).collection("session_logs").doc("location_data");
    logDurationHelper(ref, userKey, location, duration);
  }

}

// ---- HELPER METHODS ---- //

/// Helper method to add up the time from Firestore and current session 
Future<void> logDurationHelper(DocumentReference ref, String userKey, String value, int duration) async {
    final document = await ref.get();
    final log = document.data() as Map<String, dynamic>? ?? {};
    // Check if logs exists and if current location has any logged time
    if (log.containsKey(value)){
      // Add new and old time together
      duration += log[value] as int;
    }
    // Set values back to Firestore
    Map<String, dynamic> values = {
      value: duration
    };

    // Combine the data
      log.addAll(values);

    ref.set(log);
  }