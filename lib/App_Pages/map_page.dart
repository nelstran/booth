import 'dart:async';
import 'dart:convert';

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
    super.build(context);
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: currentLocation,
        padding: const EdgeInsets.only(bottom: 80),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: markers.values.toSet(),
      ),
    );
  }
}
