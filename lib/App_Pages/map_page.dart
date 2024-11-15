import 'dart:async';
import 'dart:ui' as ui;
import 'package:Booth/App_Pages/expanded_session_page.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_info_window/custom_info_window.dart';
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
import 'package:synchronized/synchronized.dart';
import 'package:Booth/MVC/analytics_extension.dart';

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
  void initState() {
    super.initState();
    isInThisSession = false;
    updateState();
  }

  updateState() {
    buttonColor = (isInThisSession ? Colors.red[900] : Colors.green[800])!;
  }

  @override
  bool get wantKeepAlive => true;
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  late GoogleMapController googleMapController;
  late BoothController controller = widget.controller;
  final customInfoWindowController = CustomInfoWindowController();
  late bool isInThisSession;
  late bool isOwner;
  late Color buttonColor;
  bool showingSnack = false;
  var lock = Lock();

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
  SizedBox rowOfPFPs(
      List<String> memberNames, int numOfPFPs, List<String> memberUIDs) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount:
            memberNames.length > numOfPFPs ? numOfPFPs : memberNames.length,
        itemBuilder: (context, index) {
          var pfpRadius = 17.0;
          var pfpFontSize = 15.0;
          return Row(
            children: [
              StreamBuilder(
                stream: widget.controller.pfpRef(memberUIDs[index]).snapshots(),
                builder: (context, snapshot) {
                  return FutureBuilder(
                    future: widget.controller
                        .getProfilePictureByUID(memberUIDs[index], true),
                    builder: (context, snapshot) {
                      return Padding(
                          padding: const EdgeInsets.all(2.0),
                          // child: ProfilePicture(
                          //   name: memberNames[index],
                          //   radius: pfpRadius,
                          //   fontsize: pfpFontSize,
                          //   img: snapshot.data,
                          // ),
                          child: CachedProfilePicture(
                              name: memberNames[index],
                              radius: pfpRadius,
                              fontSize: pfpFontSize,
                              imageUrl: snapshot.data));
                    },
                  );
                },
              ),
              if (memberNames.length > numOfPFPs && index == numOfPFPs - 1)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "+${memberNames.length - numOfPFPs}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const SizedBox.shrink()
            ],
          );
        },
      ),
    );
  }

  /// Method to add marker to the map
  void _addSession(String sessionID, Object? json) {
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
            session.ownerKey, sessionLocation, session, customIcon, sessionID);
        // Fetch owner profile picture
        addOwnerPfp(json, session, sessionID);
      }
    } catch (e) {
      // Skip if it causes any problems
    }
  }

  /// Method to set marker to owner profile picture
  Future<void> addOwnerPfp(
      dynamic json, Session session, String sessionID) async {
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

      _addMarker(
          session.ownerKey, sessionLocation, session, customIcon, sessionID);
    } catch (e) {
      // Skip
    }
  }

  /// Method to add/modify marker and add to stream to update UI
  void _addMarker(String id, LatLng location, Session session,
      BitmapDescriptor pfpIcon, String sessionID) {
    final MarkerId markerId = MarkerId(id);
    // print(session.key);

    final Marker marker = Marker(
      markerId: markerId,
      position: location,
      // infoWindow: InfoWindow(title: session.title),
      onTap: () {
        customInfoWindowController.addInfoWindow!(
            _buildCustomInfoWindow(session, sessionID), location);
      },
      icon: pfpIcon,
    );
    markers[id] = marker;
    markerStream.add(markers);
  }

  Widget _buildCustomInfoWindow(Session session, String sessionID) {
    return StreamBuilder(
      stream: widget.controller.sessionRef.child(sessionID).onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SizedBox.shrink(); // Display nothing if there’s no data.
        }
        try {
          if (controller.student.session == sessionID) {
            isInThisSession = true;
            updateState();
          } else {
            isInThisSession = false;
            updateState();
          }
          Map<dynamic, dynamic> json =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<String> memberNames = [];
          List<String> memberUIDs = [];

          json['users'].forEach((key, value) {
            memberNames.add(value['name']);
            memberUIDs.add(value['uid']);
          });

          String ownerUID = json["users"][session.ownerKey]["uid"];
          String ownerName = json["users"][session.ownerKey]["name"];

          return Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black26)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          Text(session.description,
                              maxLines: 2,
                              style: const TextStyle(
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(height: 5),
                          Text(session.time),
                        ],
                      ),
                    ),
                    StreamBuilder(
                        stream: widget.controller.pfpRef(ownerUID).snapshots(),
                        builder: (context, snapshot) {
                          return FutureBuilder(
                              future: widget.controller
                                  .getProfilePictureByUID(ownerUID, true),
                              builder: (context, snapshot) {
                                return CachedProfilePicture(
                                    name: ownerName,
                                    radius: 30,
                                    fontSize: 30,
                                    imageUrl: snapshot.data);
                              });
                        })
                    // CircleAvatar(
                    //   radius: 30,
                    //   backgroundColor: Colors.grey[300],
                    //   child: const Text("PFP"),
                    // ),
                  ],
                ),
                const SizedBox(height: 9),
                const Text("Users",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                rowOfPFPs(memberNames, 5, memberUIDs),
                const SizedBox(height: 10),
                Text(
                  "\"${session.locationDescription}\"",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    joinLeaveButton(
                        snapshot.data!.snapshot.key!, session, sessionID),
                    expandedButton(
                        snapshot.data!.snapshot.key!, session, sessionID),
                  ],
                ),
              ],
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
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
  }

  void goToHomeSchool() {
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          // University of Utah for now
          // TODO: HAVE IT UPDATE PER INSTITUTE
          target: LatLng(40.763444, -111.844182),
          zoom: 15,
        ),
      ),
    );
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
              for (var json in sessions.entries) {
                _addSession(json.key, json.value);
              }
            });
          }

          // Update map when sessions are added
          return StreamBuilder<DatabaseEvent>(
              stream: widget.controller.sessionRef.onChildAdded,
              builder: (addedCon, addedSnap) {
                // Add new session to map, we have to wait for ownerKey to be initialized
                if (addedSnap.hasData) {
                  String sessionKey = addedSnap.data!.snapshot.key!;
                  widget.controller.sessionRef
                      .child(addedSnap.data!.snapshot.key!)
                      .onValue
                      .listen((event) {
                    if (!event.snapshot.exists) {
                      return;
                    }
                    Map json = event.snapshot.value as Map;
                    if (json["ownerKey"] != "") {
                      _addSession(sessionKey, json);
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
            customInfoWindowController.googleMapController = controller;
            googleMapController = controller;
          },
          onTap: (location) {
            customInfoWindowController.hideInfoWindow!();
          },
          onCameraMove: (position) {
            customInfoWindowController.onCameraMove!();
          },
          zoomControlsEnabled: false,
        ),
        CustomInfoWindow(
          controller: customInfoWindowController,
          height: 300,
          width: 250,
          offset: 50,
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
                    for (var json in sessions.entries) {
                      _addSession(json.key, json.value);
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
        Positioned(
          top: 104,
          right: 16,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              goToHomeSchool();
            },
            child: SizedBox(
              height: 40,
              width: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 22, 22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_outlined, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Padding joinLeaveButton(String key, Session session, String sessionID) {
    int seatsLeft = session.seatsAvailable - session.seatsTaken;
    String buttonText = isInThisSession ? "Leave" : "Join";

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: seatsLeft == 0 && !isInThisSession
              ? Colors.grey[800]
              : buttonColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Center(
          child: seatsLeft == 0 && !isInThisSession
              ? const Text("Full")
              : TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: lock.locked || (seatsLeft == 0 && !isInThisSession)
                      ? null
                      : () async {
                          if (lock.locked) return;

                          await lock.synchronized(() async {
                            // Delete owned session
                            if (controller.student.ownedSessionKey != "") {
                              var sessionToDelete =
                                  controller.student.ownedSessionKey;
                              if (key == sessionToDelete) {
                                Navigator.of(context).pop();
                              }
                              await controller.removeUserFromSession(
                                  controller.student.session,
                                  controller.student.sessionKey);
                              await controller.removeSession(sessionToDelete);
                              if (key == sessionToDelete) {
                                return;
                              }
                            }

                            // Join or Leave Session Logic
                            if (isInThisSession) {
                              await controller.removeUserFromSession(
                                  sessionID, controller.student.sessionKey);
                            } else {
                              await controller.addUserToSession(
                                  sessionID, controller.student);
                              controller.startSessionLogging(
                                  controller.student.uid, session);
                            }

                            setState(() {
                              isInThisSession = !isInThisSession;
                            });
                          });
                        },
                  child: Text(key == controller.student.ownedSessionKey
                      ? "Delete"
                      : buttonText),
                ),
        ),
      ),
    );
  }

  Padding expandedButton(String key, Session session, String sessionID) {
    return Padding(
        padding: const EdgeInsets.all(1.0),
        child: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Center(
                child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // Expand session
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ExpandedSessionPage(sessionID, widget.controller),
                  ),
                );
              },
              child: const Text("Expand"),
            ))));
  }
}
