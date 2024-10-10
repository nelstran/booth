import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Map<String, Marker> markers = {};

  static const CameraPosition currentLocation = CameraPosition(
    target: LatLng(40.763444, -111.844182),
    zoom: 17,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: currentLocation,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          //addMarker();
        },
        markers: markers.values.toSet(),
      ),
    );
  }

  addMarker(String id, LatLng location) {
    final String markerIdVal = '1';
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(40.763444, -111.844182),
      infoWindow: InfoWindow(title: 'Salt Lake City'),
    );

    setState(() {
      markers[markerIdVal] = marker;
    });
  }
}
