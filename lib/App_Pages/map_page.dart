import 'dart:async';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:Booth/MVC/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:Booth/App_Pages/filter_ui.dart';
import 'package:Booth/App_Pages/session_page.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/Helper_Functions/filter_sessions.dart';
import 'package:Booth/MVC/profile_extension.dart';
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
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  Map<String, Marker> markers = {};
  LatLng? maxPos;
  LatLng? minPos;
  Map filters = {};

  static const CameraPosition currentLocation = CameraPosition(
    target: LatLng(40.763444, -111.844182),
    zoom: 15,
  );

  Future<void> _loadSessionsAndAddMarkers() async {
    Map<dynamic, dynamic> studentJson = await widget.controller.getUserEntry();

    widget.controller.sessionRef.onValue.listen((DatabaseEvent event) {
      markers.clear();
      final dataSnapshot = event.snapshot;

      if (dataSnapshot.value == null) {
        print('No session data available.');
        return;
      }

      final Map<dynamic, dynamic>? sessions =
          dataSnapshot.value as Map<dynamic, dynamic>?;
      final Map<dynamic, dynamic>? filteredSessions = {};

      if (sessions != null) {
        sessions.forEach((key, session) async {
          Session sesh = Session.fromJson(session);

          if (!isFiltered(filters, sesh) &&
              sesh.latitude != null &&
              sesh.longitude != null) {
            final LatLng sessionLocation =
                LatLng(sesh.latitude!, sesh.longitude!);
            String sessionKey = key.toString();

            // Load owner profile (if not loaded)
            Object? result = await widget.controller.getUid(
              studentJson["profile"]["institution"],
              sessionKey,
              sesh.ownerKey,
            );

            String? ownerKey;
            if (result is Map) {
              ownerKey = result['uid'];
            } else {
              print("No valid UID found, result: $result");
            }

            String? ownerPfpPath =
                await widget.controller.retrieveProfilePicture(ownerKey!);

            BitmapDescriptor customIcon;

            // Load the owner's profile picture
            if (ownerPfpPath != null) {
              try {
                final Uint8List? ownerPfpBytes =
                    await loadNetworkImage(ownerPfpPath, 35);
                customIcon = BitmapDescriptor.bytes(ownerPfpBytes!);
              } catch (e) {
                print("Error loading profile picture: $e");
                customIcon = BitmapDescriptor.defaultMarker;
              }
            } else {
              customIcon = BitmapDescriptor
                  .defaultMarker; // Fallback if no path is found
            }

            _addMarker(sesh.ownerKey, sessionLocation, sesh.title, customIcon);
          }
        });
      }
    });
  }

  Future<Uint8List> getBytesFromAsset(
      {required String path, required int width}) async {
    final ByteData _data = await rootBundle.load(path);
    final ui.Codec _codec = await ui
        .instantiateImageCodec(_data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo _fi = await _codec.getNextFrame();
    final Uint8List _bytes =
        (await _fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return _bytes;
  }

  Future<Uint8List?> loadNetworkImage(String imageUrl, int width) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final ui.Codec codec = await ui.instantiateImageCodec(
          response.bodyBytes,
          targetWidth: width,
        );
        final ui.FrameInfo frameInfo = await codec.getNextFrame();

        final ui.Image image = frameInfo.image;
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        final Paint paint = Paint()..isAntiAlias = true;

        final double radius = width / 2;
        canvas.drawCircle(Offset(radius, radius), radius, paint);
        paint.blendMode = BlendMode.srcIn;
        canvas.drawImage(image, const Offset(0, 0), paint);

        final ui.Image circularImage =
            await recorder.endRecording().toImage(width, width);
        final ByteData? byteData =
            await circularImage.toByteData(format: ui.ImageByteFormat.png);
        return byteData!.buffer.asUint8List();
      } else {
        print("Failed to load network image: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading network image: $e");
    }
    return null;
  }

  void _addMarker(
      String id, LatLng location, String title, BitmapDescriptor pfpIcon) {
    final MarkerId markerId = MarkerId(id);

    final Marker marker = Marker(
      markerId: markerId,
      position: location,
      infoWindow: InfoWindow(title: title),
      icon: pfpIcon,
    );

    setState(() {
      markers[id] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
        stream: widget.controller.profileRef.child("institution").onValue,
        builder: (context, snapshot) {
          _controller = Completer<GoogleMapController>();
          _loadSessionsAndAddMarkers();
          return Stack(
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
          );
        });
  }
}
