import 'dart:async';
import 'dart:ui' as ui;
import 'package:Booth/MVC/session_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:Booth/App_Pages/filter_ui.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:Booth/Helper_Functions/filter_sessions.dart';
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
  late GoogleMapController googleMapController;

  Map<String, Marker> markers = {};
  LatLng? maxPos;
  LatLng? minPos;
  Map filters = {};
  StreamSubscription schoolSubscription = const Stream.empty().listen((_) {});
  StreamSubscription sessionSubscription = const Stream.empty().listen((_) {});
  StreamController<Map<String, Marker>> markerStream =
      StreamController<Map<String, Marker>>();

  static const CameraPosition currentLocation = CameraPosition(
    target: LatLng(40.763444, -111.844182),
    zoom: 15,
  );

  // Future<void> loadSessionsAndAddMarkers(event) async {
  //   if (event == null){
  //     return;
  //   }
  //   final dataSnapshot = event.snapshot;

  //   if (dataSnapshot.value == null) {
  //     print('No session data available.');
  //     return;
  //   }

  //   final Map<dynamic, dynamic>? sessions =
  //       dataSnapshot.value as Map<dynamic, dynamic>?;

  //   if (sessions != null) {
  //     for (var json in sessions.values){
  //     // sessions.forEach((key, json) async {
  //       try {
  //         Session session = Session.fromJson(json);

  //         if (!isFiltered(filters, session) &&
  //             session.latitude != null &&
  //             session.longitude != null) {

  //               const BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  //               final LatLng sessionLocation = LatLng(session.latitude!, session.longitude!);
  //               _addMarker(session.ownerKey, sessionLocation, session.title, customIcon);
  //               addOwnerPfp(json, session);
  //         }
  //       }
  //       catch (e) {
  //         // Skip if it causes any problems
  //       }
  //     }
  //     return;
  //   }
  //   else{
  //     return;
  //   }
  // }

  /// Method to add marker to the map
  void _addSession(Object? json) {
    if (json == null) {
      return;
    }

    try {
      Session session = Session.fromJson(json as Map);

      if (!isFiltered(filters, session) &&
          session.latitude != null &&
          session.longitude != null) {
        const BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
        final LatLng sessionLocation =
            LatLng(session.latitude!, session.longitude!);
        // Add marker first and get profile picture in the background for better responsiveness
        _addMarker(
            session.ownerKey, sessionLocation, session.title, customIcon);
        // Fetch owner profile picture
        addOwnerPfp(json, session);
      }
    } catch (e) {
      // Skip if it causes any problems
    }
  }

  /// Method to set marker to owner profile picture
  Future<void> addOwnerPfp(dynamic json, Session session) async {
    try {
      final LatLng sessionLocation =
          LatLng(session.latitude!, session.longitude!);

      // // Load owner profile (if not loaded)
      // Object? result = await widget.controller.getUid(
      //   studentJson["profile"]["institution"],
      //   sessionKey,
      //   session.ownerKey,
      // );

      String ownerUID = json["users"][session.ownerKey]["uid"];

      String? ownerPfpPath =
          await widget.controller.retrieveProfilePicture(ownerUID);

      BitmapDescriptor customIcon;

      // Load the owner's profile picture
      if (ownerPfpPath != null) {
        try {
          final Uint8List? ownerPfpBytes =
              await loadNetworkImage(ownerPfpPath, 40);
          customIcon = BitmapDescriptor.bytes(ownerPfpBytes!);
        } catch (e) {
          print("Error loading profile picture: $e");
          customIcon = BitmapDescriptor.defaultMarker;
        }
      } else {
        customIcon =
            BitmapDescriptor.defaultMarker; // Fallback if no path is found
      }

      _addMarker(session.ownerKey, sessionLocation, session.title, customIcon);
    } catch (e) {
      // Skip
    }
  }

  /// Method to add/modify marker and add to stream to update UI
  void _addMarker(
      String id, LatLng location, String title, BitmapDescriptor pfpIcon) {
    final MarkerId markerId = MarkerId(id);

    final Marker marker = Marker(
      markerId: markerId,
      position: location,
      infoWindow: InfoWindow(title: title),
      icon: pfpIcon,
    );
    markers[id] = marker;
    markerStream.add(markers);
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
      final cacheManager = DefaultCacheManager();
      // No need to check if url is valid since we're in a try/catch
      final file = await cacheManager.getSingleFile(imageUrl);
      final fileBytes = await file.readAsBytes();

      final ui.Codec codec = await ui.instantiateImageCodec(
        fileBytes,
        targetWidth: 40,
        targetHeight: 40,
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
      // final response = await http.get(Uri.parse(imageUrl));

      // if (response.statusCode == 200) {
      //   final ui.Codec codec = await ui.instantiateImageCodec(
      //     response.bodyBytes,
      //     targetWidth: width,
      //   );
      //   final ui.FrameInfo frameInfo = await codec.getNextFrame();

      //   final ui.Image image = frameInfo.image;
      //   final ui.PictureRecorder recorder = ui.PictureRecorder();
      //   final Canvas canvas = Canvas(recorder);
      //   final Paint paint = Paint()..isAntiAlias = true;

      //   final double radius = width / 2;
      //   canvas.drawCircle(Offset(radius, radius), radius, paint);
      //   paint.blendMode = BlendMode.srcIn;
      //   canvas.drawImage(image, const Offset(0, 0), paint);

      //   final ui.Image circularImage =
      //       await recorder.endRecording().toImage(width, width);
      //   final ByteData? byteData =
      //       await circularImage.toByteData(format: ui.ImageByteFormat.png);
      //   return byteData!.buffer.asUint8List();
      // } else {
      //   print("Failed to load network image: ${response.statusCode}");
      // }
    } catch (e) {
      print("Error loading network image: $e");
    }
    return null;
  }

  void currentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Checking if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // Checking the location permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Requesting permission if it is denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    // Handling the case where permission is permanently denied
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // Getting the current position of the user
    Position position = await Geolocator.getCurrentPosition();

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
        ),
      ),
    );
    // LocationData? currentLocation;
    // var location = Location();

    // Position position =

    // try {
    //   currentLocation = await location.getLocation();
    // } on Exception {
    //   currentLocation = null;
    // }

    // if (currentLocation != null) {
    //   controller.animateCamera(CameraUpdate.newCameraPosition(
    //     CameraPosition(
    //       bearing: 0,
    //       target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
    //       zoom: 17.0,
    //     ),
    //   ));
    // } else {
    //   print("Failed to get current location.");
    // }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Update map when changing schools
    return StreamBuilder<DatabaseEvent>(
        stream: widget.controller.profileRef.onValue,
        builder: (profCon, profSnap) {
          // Get all existing sessions and add to map
          if (profSnap.hasData) {
            // Reset map
            markers.clear();
            markerStream.add(markers);

            // Get new existing session
            widget.controller
                .getSessions(
                    (profSnap.data!.snapshot.value as Map)["institution"])
                .then((sessions) {
              for (var json in sessions.values) {
                _addSession(json);
              }
            });
          }

          // Update map when sessions are added
          return StreamBuilder<DatabaseEvent>(
              stream: widget.controller.sessionRef.onChildAdded,
              builder: (addedCon, addedSnap) {
                // Add new session to map, we have to wait for ownerKey to be initialized
                if (addedSnap.hasData) {
                  widget.controller.sessionRef
                      .child(addedSnap.data!.snapshot.key!)
                      .onValue
                      .listen((event) {
                    if (!event.snapshot.exists) {
                      return;
                    }
                    Map json = event.snapshot.value as Map;
                    if (json["ownerKey"] != "") {
                      _addSession(json);
                    }
                  });
                }
                // Update map when sessions are removed
                return StreamBuilder<DatabaseEvent>(
                    stream: widget.controller.sessionRef.onChildRemoved,
                    builder: (removedCon, removedSnap) {
                      // Remove marker from deleted sessions
                      if (removedSnap.hasData) {
                        String id = (removedSnap.data!.snapshot.value
                            as Map)["ownerKey"];
                        markers.remove(id);
                        markerStream.add(markers);
                      }
                      // Update map when markers are added
                      return StreamBuilder<Map<String, Marker>>(
                          stream: markerStream.stream,
                          builder: (context, snapshot) {
                            Set<Marker> localMarkers = Set.identity();
                            if (snapshot.hasData) {
                              localMarkers = snapshot.data!.values.toSet();
                            }
                            return mapUI(context, localMarkers);
                          });
                    });
              });
        });
  }

  Stack mapUI(BuildContext context, Set<Marker> markers) {
    return Stack(
      children: <Widget>[
        GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: currentLocation,
          padding: const EdgeInsets.only(bottom: 80),
          // onMapCreated: (GoogleMapController controller) {
          //   _controller.complete(controller);
          // },
          markers: markers,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            googleMapController = controller;
          },
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
                  widget.controller.getSessions().then((sessions) {
                    for (var json in sessions.values) {
                      _addSession(json);
                    }
                  });
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
        Positioned(
          top: 60,
          right: 16,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              currentPosition();
            },
            child: SizedBox(
              height: 40,
              width: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 22, 22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Transform.rotate(
                  angle: 0.75,
                  child: const Icon(Icons.navigation_outlined,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
