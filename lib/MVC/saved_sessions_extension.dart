import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension SavedSessionsExtension on BoothController {

  CollectionReference get savedSessionRef => firestoreDb.db
    .collection("users")
    .doc(student.uid)
    .collection("saved_sessions");

  /// Creates a document in Firestore that stores the session the user wants to save
  Future<void> saveSession(String userKey, Session session) async {
      session.key = "";
      session.ownerKey = "";
      session.latitude = null;
      session.longitude = null;
      session.address = null;
      session.imageURL = null;
      
      Map<String, dynamic> valuesToLog = session.toJson();
      var endTime = Timestamp.now();
      var filename = endTime.millisecondsSinceEpoch.toString();
      await firestoreDb.saveSession(userKey, valuesToLog, filename);
    }

  /// Removes session from saved sessions 
  Future<void> unsaveSession(String userKey, String filename) async {
      await firestoreDb.unsaveSession(userKey, filename);
    }

  /// Grabs user saved sessions from Firestore, [userKey] uses UID
  Future<Map<String, dynamic>> fetchuserSavedSessions(String userKey) async {
      final doc = await firestoreDb.fetchuserSavedSessions(userKey);
      if (doc == null || doc.isEmpty) {
        return {};
      }
      return doc;
    }
}