import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/session_model.dart';
import 'package:intl/intl.dart';
import 'package:logger/web.dart';

extension AnalyticsExtension on BoothController {
  // ---- USER ANALYTICS ---- //
  /// Creates an entry in the Firestore that stores what subject the user
  /// is studying and what location it is at while also taking note of the time they started.
  void startSessionLogging(String userKey, Session session) {
    var format = DateTimeFormat.dateAndTime;
    var timestamp = Timestamp.now().toDate();
    var todayInDays =
        timestamp.difference(DateTime(timestamp.year, 1, 1, 0, 0)).inDays;
    var weekNumber = ((todayInDays - timestamp.weekday + 10) / 7).floor();
    Map<String, dynamic> valuesToLog = {
      "start_timestamp": format(timestamp),
      "month": DateFormat.MMMM().format(timestamp),
      "day_of_month": int.parse(DateFormat.d().format(timestamp)),
      "day_of_week": DateFormat.EEEE().format(timestamp),
      "day_of_year": int.parse(todayInDays.toString()),
      "week_of_year": weekNumber,
      "subject": session.subject,
      "location_desc": session.locationDescription
    };

    firestoreDb.startSessionLogging(userKey, valuesToLog);
  }

  /// Grabs the starting log from Firestore and finalize the data for analytics.
  /// The data in curr_session should be in its own respective document containing data
  /// for easy querying.
  Future<void> endSessionLogging(String userKey) async {
    var doc = await firestoreDb.endSessionLogging(userKey);
    if (doc == null) {
      return;
    }

    var format = DateTimeFormat.dateAndTime;
    var endTime = Timestamp.now();
    var timestamp = format(endTime.toDate());
    var filename = endTime.millisecondsSinceEpoch.toString();
    doc['end_timestamp'] = timestamp;

    // Logs subject and time in seconds
    await firestoreDb.logSession(userKey, doc, filename);
  }

  Future<Map<String, dynamic>> fetchUserStudyData(String userKey) async {
    final doc = await firestoreDb.fetchuserStudyData(userKey);
    if (doc == null || doc.isEmpty) {
      return {};
    }
    doc.remove('curr_session');
    return doc;
  }
}