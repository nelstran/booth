import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreDatabase {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  FirestoreDatabase();

  /// Adds a user entry to Firestore, [userKey] uses UID
  Future<void> addUserData(String key) async {
    await db.collection("users").doc(key).set({});
  }

  /// Retrieves user entry from Firestore, [userKey] uses UID
  Future<Map<String, dynamic>?> getUserData(String userKey) async {
    final ref = db.collection("users").doc(userKey);

    try {
      final doc = await ref.get();
      return doc.data();
    } catch (error) {
      return Future.error(error);
    }
  }

  /// Removes user data from Firestore, [userKey] uses UID
  Future<void> removeUserData(String userKey) async {
    final ref = db.collection("users").doc(userKey);
    await ref.delete();
  }

  /// Gather data of session the user joins to start logging, [userKey] uses UID
  void startSessionLogging(String userKey, Map<String, dynamic> valuesToLog) {
    // Equivalent to 'users/{userKey}/session_logs/curr_session
    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("session_logs")
        .doc("curr_session");
    ref.set(valuesToLog);
  }

  /// Clear the curr_session document in Firebase for the given user, [userKey] uses UID
  Future<Map<String, dynamic>?> endSessionLogging(String userKey) async {
    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("session_logs")
        .doc("curr_session");

    try {
      final doc = await ref.get();
      ref.set({});
      return doc.data();
    } catch (error) {
      return Future.error(error);
    }
  }

  /// Adds the given log to Firestore for analytics
  Future<void> logSession(
      String userKey, Map<String, dynamic> document, String filename) async {
    final ref = db
        .collection('users')
        .doc(userKey)
        .collection('session_logs')
        .doc(filename);
    await ref.set(document);
  }

  /// Grabs user study data from Firestore, [userKey] uses UID
  Future<Map<String, dynamic>?> fetchuserStudyData(String userKey) async {
    final ref = db.collection("users").doc(userKey).collection("session_logs");
    return await getDataFromRef(ref);
  }

  /// Uploads the given file to Firebase Storage with the given filename
  Future<Reference> uploadProfilePictureStorage(XFile file, String filename) async {
    // String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();

    final refRoot = storage.ref();
    final refDirPFP = refRoot.child("profile_pictures");

    Reference refUpload = refDirPFP.child(filename);

    print("new file path" + file.path);

    try {
      await refUpload.putFile(File(file.path));
      return refUpload;
    } catch (error) {
      return Future.error(error);
    }
  }

  /// Uploads the given file to Firebase Storage with the given filename
  Future<Reference> uploadSessionPictureStorage(File file, String filename) async {
    // String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();

    final refRoot = storage.ref();
    final refDirPFP = refRoot.child("session_pictures");

    Reference refUpload = refDirPFP.child(filename);

    try {
      await refUpload.putFile(file);
      return refUpload;
    } catch (error) {
      return Future.error(error);
    }
  }

  /// Delete session image given the [sessionKey]
  Future<void> deleteSessionPicture(String sessionKey) async {
    try{
      final refStorage = storage.ref();
      final sessionRef = refStorage.child("session_pictures/$sessionKey");
      await sessionRef.delete();
    }
    catch (e){
      return;
    }
  }

  /// Adds the URL of the user's profile picture to Firestore for later retrieval, [userKey] uses UID
  Future<void> uploadProfilePictureFireStore(Map<String, String> pfpStorage, String userKey) async {
    Map<String, String> data = {"profile_picture": pfpStorage['url']!};

    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("user_pictures")
        .doc("pfp_url");

    await ref.set(data);
  }

  /// Goes into Firestore to get the profile picture URL, [userKey] uses UID
  Future<String?> retrieveProfilePicture(String userKey) async {
    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("user_pictures")
        .doc("pfp_url");

    try {
      final doc = await ref.get();
      final data = doc.data();
      if (data != null && data.containsKey('profile_picture')){
        return data['profile_picture'];
      }
      else{
        return null;
      }
    } catch (error) {
      print(error);
      return null;
    }
  }

  /// Deletes user profile picture from storage, [userKey] uses UID
  Future<void> deleteProfilePictureStorage(String userKey) async  {
    try {
      final refStorage = storage.ref();
      final pfpRef = refStorage.child("profile_pictures/$userKey");
      await pfpRef.delete();
    }
    catch (error) {
      return;
    }
  }

  /// Removes URL of user's profile picture from Firestore, [userKey] uses UID
  Future<void> deleteProfilePictureFirestore(String userKey) async {
    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("user_pictures")
        .doc("pfp_url");

    await ref.set({});
  }

  Future<Map<String,dynamic>> getSessionMessages(String sessionKey) async {
    final ref = db.collection("sessions").doc(sessionKey).collection("chat_room");
    return await getDataFromRef(ref);
  }

  Future<Map<String, dynamic>> getDataFromRef(CollectionReference ref) async {
    try {
      final snapshot = await ref.get();
      Map<String, dynamic> docs = {};
      for (var query in snapshot.docs) {
        docs[query.id] = query.data();
      }
      return docs;
    } catch (error) {
      return {};
    }
  }
}

// ---- HELPER METHODS ---- //

/// Helper method to add up the time from Firestore and current session
Future<void> logDurationHelper(
    DocumentReference ref, String userKey, String value, int duration) async {
  final document = await ref.get();
  final log = document.data() as Map<String, dynamic>? ?? {};
  // Check if logs exists and if current location has any logged time
  if (log.containsKey(value)) {
    // Add new and old time together
    duration += log[value] as int;
  }
  // Set values back to Firestore
  Map<String, dynamic> values = {value: duration};

  // Combine the data
  log.addAll(values);

  ref.set(log);
}
