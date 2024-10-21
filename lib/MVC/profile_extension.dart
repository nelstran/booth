import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

extension ProfileExtension on BoothController {
  DatabaseReference get profileRef => ref.child("users/${student.key}/profile");

  DocumentReference pfpRef([String? userKey]) {
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
    Map<String, String> pfpStorage =
        await _uploadProfilePictureStorage(file, userKey);
    await _uploadProfilePictureFireStore(pfpStorage, userKey);
  }

  /// Private helper method that uploads the given file to Firebase Storage
  /// If [userKey] is null, it will default to the student associated with the controller
  Future<Map<String, String>> _uploadProfilePictureStorage(XFile file,
      [String? userKey]) async {
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

  /// Helper future method to fetch the profile picture Image URL from the database and checks
  /// if the URL is valid; if it is not valid, return null, else return the valid URL
  /// [uid] defaults to logged in user's UID if none is given
  Future<String?> getProfilePictureByUID([String? uid]) async {
    uid = uid ?? student.uid;
    // Get URL from Firestore
    String? pfp = await retrieveProfilePicture(uid);
    if (pfp == null) {
      return pfp;
    } else {
      // Grabs response of given url
      final response = await http.get(Uri.parse(pfp));
      if (response.statusCode == 200) {
        return pfp;
      } else {
        return Future.error("ERROR 404");
      }
    }
  }

  /// Helper method to get profile picture by user's key in the database
  Future<String?> getProfilePictureByKey([String? key]) async {
    key = key ?? student.key;
    Map json = await getUserEntry(key);
    // Get URL from Firestore
    return await getProfilePictureByUID(json['uid']);
  }
}
