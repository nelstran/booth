import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

extension SampleExtension on BoothController {
  static String namesFilePath = 'assets/mock/names.json';
  static String sessionFilePath = 'assets/mock/sessions.json';
  static String locationFilePath = 'assets/mock/location_desc.json';


  Future<void> createNSampleSessions(int n) async{
    var nameJson = await rootBundle.loadString(namesFilePath);
    var sessionjson = await rootBundle.loadString(sessionFilePath);
    var locationjson = await rootBundle.loadString(locationFilePath);

    var names = jsonDecode(nameJson)['names'] as List;
    var sessions = jsonDecode(sessionjson)['sessions'] as Map;
    var locations = jsonDecode(locationjson)['location_desc'] as List;

    var rng = Random();

    var sampleSession = [];

    // Randomly generate N sessions 
    for(var i = 0; i < n; i++){
      var sampleName = [];
      var location = "";
      // Get a unique random session from json file
      var sessionIndex = rng.nextInt(sessions.length);
      while (sampleSession.contains(sessionIndex)){
        sessionIndex = rng.nextInt(sessions.length);
      }
      sampleSession.add(sessionIndex); 

      // Grab a random amount of names to assign to the random session
      var numOfNames = rng.nextInt(10) + 1;
      var nameIndex = rng.nextInt(names.length);
      for(var j = 0; j < numOfNames; j++){
        while(sampleName.contains(names[nameIndex])){
          nameIndex = rng.nextInt(names.length);
        }
        sampleName.add(names[nameIndex]);
      }

      // Get a random location to set the session
      var locationIndex = rng.nextInt(locations.length);
      location = locations[locationIndex];

      // Set random amount of max seating for session
      var maxSeats = rng.nextInt(5) + numOfNames;

      Map session = sessions[sessionIndex.toString()];

      // Create map from list of names
      Map nameMap = sampleName.asMap();
      // Modify map to make it suitable for Firebase
      Map properMap = {};
      nameMap.forEach((key, value){
        properMap["key$key"] = {
          "name": value,
          "uid": "123456789"
        };
      });

      Map sample = {
        "title": session['title'],
        "description": session['desc'],
        "subject": session['subject'],
        "seatsAvailable": maxSeats,
        "locationDescription": location,
        "time": "9:00am - 12:00pm",
        "isPublic": true,
        "field": "field",
        "level": 1000,
        "ownerKey": "sample",
        "users": properMap
      };
      await db.createSampleSession(sample);
    }
  }
}