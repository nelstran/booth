import 'dart:async';
import 'dart:convert';

import 'package:Booth/App_Pages/filter_ui.dart';
import 'package:Booth/MVC/session_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.ref,
    required this.controller,
  });

  final DatabaseReference ref;
  final BoothController controller;

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Map<String, Marker> markers = {};
  LatLng? maxPos;
  LatLng? minPos;
  Map filters = {};

  static const CameraPosition currentLocation = CameraPosition(
    target: LatLng(40.763444, -111.844182),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _loadSessionsAndAddMarkers();
  }

  Future<void> _loadSessionsAndAddMarkers() async {
    widget.controller.sessionRef.onValue.listen((DatabaseEvent event) {
      markers.clear();
      final dataSnapshot = event.snapshot;

      // Check if dataSnapshot.value is null
      if (dataSnapshot.value == null) {
        print('No session data available.');
        return;
      }

      final Map<dynamic, dynamic>? sessions =
          dataSnapshot.value as Map<dynamic, dynamic>?;
      final Map<dynamic, dynamic>? filteredSessions = {};

      if (sessions != null) {
        sessions.forEach((key, session) {
          print(session);
          Session sesh = Session.fromJson(session);

          if (isFiltered(sesh)) {
            print("isFiltered: ${sesh.title}");
          } else {
            print("Not filtered: ${sesh.title}");
            if (sesh.latitude != null && sesh.longitude != null) {
              final LatLng sessionLocation =
                  LatLng(sesh.latitude!, sesh.longitude!);
              _addMarker(key, sessionLocation, sesh.title);
              print(
                  '${key} marker for session: ${sesh.title} at location: ${sesh.latitude}, ${sesh.longitude}');
            }

            //filteredSessions![key] = session;
          }
        });
        // filteredSessions!.forEach((key, session) {
        //   Session sesh = Session.fromJson(session);

        //   if (sesh.latitude != null && sesh.longitude != null) {
        //     final LatLng sessionLocation =
        //         LatLng(sesh.latitude!, sesh.longitude!);
        //     _addMarker(sesh.key, sessionLocation, sesh.title);
        //     print(
        //         'Adding marker for session: ${sesh.title} at location: ${sesh.latitude}, ${sesh.longitude}');
        //   }
        // });
      }
    });
  }

  void _addMarker(String id, LatLng location, String title) {
    final MarkerId markerId = MarkerId(id);

    final Marker marker = Marker(
      markerId: markerId,
      position: location,
      infoWindow: InfoWindow(title: title),
    );

    setState(() {
      markers[id] = marker;
    });
  }

  // Method to manually filter session on user's device since realtime database does not
  // offer any filtering
  bool isFiltered(Session session) {
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
        if (!(filters['locationFilters'] as List).any((location) => session
            .locationDescription
            .toLowerCase()
            .contains((location as String).toLowerCase()))) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: currentLocation,
            padding: const EdgeInsets.only(bottom: 80),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: markers.values.toSet(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                showModalBottomSheet(
                  showDragHandle: true,
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return Wrap(children: [FilterUI(filters)]);
                  },
                ).then((value) {
                  if (value == null) return;
                  setState(() {
                    filters.clear();
                    filters.addAll(value);
                    markers.clear();
                    _loadSessionsAndAddMarkers();
                  });
                });
              },
              child: SizedBox(
                height: 40,
                width: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 22, 22, 22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
