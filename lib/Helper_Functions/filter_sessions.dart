import 'package:Booth/MVC/session_model.dart';

// Method to manually filter session on user's device since realtime database does not
// offer any filtering
bool isFiltered(Map filters, Session session) {
    // Hide full sessions
    if (filters.containsKey('hideFull') && filters['hideFull']) {
      if (session.seatsTaken == session.seatsAvailable) {
        return true;
      }
    }

    // Hide sessions with less than x free seats
    if (filters.containsKey('currMinSliderValue')) {
      if (filters['currMinSliderValue'] > 0) {
        if (session.seatsAvailable - session.seatsTaken <
            filters['currMinSliderValue']) {
          return true;
        }
      }
    }

    // Hide sessions with lobbies bigger than x people
    if (filters.containsKey('currMaxSliderValue')) {
      if (filters['currMaxSliderValue'] != 25) {
        if (session.seatsAvailable > filters['currMaxSliderValue']) {
          return true;
        }
      }
    }

    // Show sessions that have location descriptions that contain a list of words
    if (filters.containsKey('locationFilters')) {
      if ((filters['locationFilters'] as List).isNotEmpty) {
        // Check if location description contains the word not the letters
        var result = !(filters['locationFilters'] as List).any((location) =>
          session.locationDescription.toLowerCase().split(" ")
          .contains((location as String).toLowerCase()));
        if (result){
          return true;
        }
      }
    }

    // Show only sessions that are for a certain class
    if (filters.containsKey('classFilter')) {
      if (session.subject.toUpperCase() !=
          (filters['classFilter'] as String).toUpperCase()) {
        return true;
      }
    }
    return false;
  }