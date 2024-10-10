import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:image_picker/image_picker.dart';

extension ProfileExtension on BoothController {
  DatabaseReference get profileRef => ref.child("users/${student.key}/profile");

  DocumentReference pfpRef([String? userKey]){
    userKey = userKey ?? student.uid;
    return firestoreDb.db
    .collection("users")
    .doc(userKey)
    .collection("user_pictures")
    .doc("pfp_url");
  }
  
  /// Update the current user's profile
  void updateUserProfile(Map<String, Object?> value) {
    db.updateProfile(student.key, value);
  }

  /// Given a user key, will delete the associated profile picture from Firebase.
  /// If [userKey] is null, it will default to the student associated with the controller
  Future<void> deleteProfilePicture([String? userKey]) async {
    userKey = userKey ?? student.uid;
    await firestoreDb.deleteProfilePictureStorage(userKey);
    await firestoreDb.deleteProfilePictureFirestore(userKey);
  }
  
  /// Given a file, will upload and set what user is associated with the image in Firebase
  /// If [userKey] is null, it will default to the student associated with the controller
  Future<void> uploadProfilePicture(XFile file, [String? userKey]) async {
    userKey = userKey ?? student.uid;
    Map<String, String> pfpStorage = await _uploadProfilePictureStorage(file, userKey);
    await _uploadProfilePictureFireStore(pfpStorage, userKey);
  }

  /// Private helper method that uploads the given file to Firebase Storage
  /// If [userKey] is null, it will default to the student associated with the controller
  Future<Map<String, String>> _uploadProfilePictureStorage(XFile file, [String? userKey]) async {
    userKey = userKey ?? student.uid;
    final ref = await firestoreDb.uploadProfilePictureStorage(file, userKey);
    String url = await ref.getDownloadURL();
    return {"url": url};
  }

  /// Private helper method that uploads the given file to Firestore
  /// If [userKey] is null, it will default to the student associated with the controller
  Future<void> _uploadProfilePictureFireStore(
      Map<String, String> pfpStorage, String userKey) async {
    await firestoreDb.uploadProfilePictureFireStore(pfpStorage, userKey);
  }

  /// Retrieves the profile picture associated with the given userKey
  Future<String?> retrieveProfilePicture(String userKey) async {
    return await firestoreDb.retrieveProfilePicture(userKey);
  }
}