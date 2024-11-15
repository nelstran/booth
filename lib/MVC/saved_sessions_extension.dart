import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension SavedSessionsExtension on BoothController {

  /// Creates a document in Firestore that stores the session the user wants to save
  Future<void> saveSession(String userKey, Session session) async {

      // Map<String, dynamic> valuesToLog = {
      //   'title': session.title,
      //   'description': session.description,
      //   'time': session.time,
      //   'locationDescription': session.locationDescription,
      //   'seatsAvailable': session.seatsAvailable,
      //   'subject': session.subject,
      //   'isPublic': session.isPublic,
      //   'field': session.field,
      //   'level': session.level,
      //   'key': session.key,
      //   'ownerKey': session.ownerKey,
      //   'latitude': session.latitude,
      //   'longitude': session.longitude,
      //   'address': session.address,
      //   'imageURL': session.imageURL
      // };
      session.key = "";
      Map<String, dynamic> valuesToLog = session.toJson();

      var endTime = Timestamp.now();
      var filename = endTime.millisecondsSinceEpoch.toString();
      await firestoreDb.saveSession(userKey, valuesToLog, filename);
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