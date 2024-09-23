import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreDatabase {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  FirestoreDatabase();

  void addUserData(String key) {
    db.collection("users").doc(key).set({});
  }

  Future<Map<String, dynamic>?> getUserData(String userKey) async {
    final ref = db.collection("users").doc(userKey);

    try {
      final doc = await ref.get();
      return doc.data();
    } catch (error) {
      return Future.error(error);
    }
  }

  /// Gather data of session the user joins to start logging
  void startSessionLogging(String userKey, Map<String, dynamic> valuesToLog) {
    // Equivalent to 'users/{userKey}/session_logs/curr_session
    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("session_logs")
        .doc("curr_session");
    ref.set(valuesToLog);
  }

  /// Clear the curr_session document in Firebase for the given user
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

  Future<void> logSession(
      String userKey, Map<String, dynamic> document, String filename) async {
    final ref = db
        .collection('users')
        .doc(userKey)
        .collection('session_logs')
        .doc(filename);
    await ref.set(document);
  }

  /// Grabs user data from Firestore
  Future<Map<String, dynamic>?> fetchuserStudyData(String userKey) async {
    final ref = db.collection("users").doc(userKey).collection("session_logs");
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

  Future<Reference> uploadProfilePictureStorage(XFile file) async {
    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();

    final refRoot = storage.ref();
    final refDirPFP = refRoot.child("profile_pictures");

    Reference refUpload = refDirPFP.child(uniqueFileName);

    print("new file path" + file.path);

    try {
      await refUpload.putFile(File(file.path));
      return refUpload;
    } catch (error) {
      return Future.error(error);
    }
  }

  Future<void> uploadProfilePictureFireStore(Map<String, String> pfpStorage, String userKey) async {
    Map<String, String> data = {"profile_picture": pfpStorage['url']!, "filepath": pfpStorage['filepath']!};

    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("user_pictures")
        .doc("pfp_url");

    await ref.set(data);
  }

  Future<String?> retrieveProfilePicture(String userKey) async {
    final ref = db
        .collection("users")
        .doc(userKey)
        .collection("user_pictures")
        .doc("pfp_url");

    try {
      final doc = await ref.get();
      return doc.data()!["profile_picture"];
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<void> deleteProfilePictureStorage(String userKey) async  {
    final ref = db.collection("users")
        .doc(userKey)
        .collection("user_pictures")
        .doc("pfp_url");

    try {
      final doc = await ref.get();
      final filepath = doc.data()!["filepath"];
      final refStorage = storage.ref(filepath);
      await refStorage.delete();
    }
    catch (error) {
      return;
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
