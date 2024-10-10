import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
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

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Map<String, Marker> markers = {};

  static const CameraPosition currentLocation = CameraPosition(
    target: LatLng(40.763444, -111.844182),
    zoom: 1,
  );

  @override
  void initState() {
    super.initState();
    _loadSessionsAndAddMarkers();
  }

  Future<void> _loadSessionsAndAddMarkers() async {
    widget.controller.sessionRef.once().then((DatabaseEvent event) {
      final dataSnapshot = event.snapshot;
      final Map<dynamic, dynamic>? sessions =
          dataSnapshot.value as Map<dynamic, dynamic>?;

      if (sessions != null) {
        sessions.forEach((key, session) {
          if (session['latitude'] != null && session['longitude'] != null) {
            final LatLng sessionLocation =
                LatLng(session['latitude'], session['longitude']);

            _addMarker(key, sessionLocation, session['title']);
          }
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: currentLocation,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: markers.values.toSet(),
      ),
    );
  }
}
