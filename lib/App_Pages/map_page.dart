import 'dart:async';
import 'dart:ui' as ui;
import 'package:Booth/App_Pages/expanded_session_page.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/UI_components/cached_profile_picture.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
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

// final places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

/// This class is the main page for the map view.
/// It displays a Google Map with markers for each session.
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
  CameraPosition? currentLocation;

  @override
  void initState() {
    super.initState();
    initializeLocation();
    isInThisSession = false;
    updateState();
  }

  /// Initialize the map's camera position to the institution's coordinates.
  Future<void> initializeLocation() async {
    setState(() {
      currentLocation = const CameraPosition(
        target: LatLng(40.763444, -111.844182),
        zoom: 15,
      );
    });
    // try {
    //   final school =
    //       await getInstitutionLatLng(widget.controller.studentInstitution);
    //   if (school != null) {
    //     setState(() {
    //       currentLocation = CameraPosition(
    //         target: LatLng(school['latitude']!, school['longitude']!),
    //         zoom: 15,
    //       );
    //     });
    //   } else {
    //     debugPrint("Failed to retrieve institution coordinates.");
    //   }
    // } catch (e) {
    //   debugPrint("Error initializing location: $e");
    // }
  }

  // This function is called when the user joins or leave a session
  // which changes the color of the button
  updateState() {
    buttonColor = (isInThisSession ? Colors.red[900] : Colors.green[800])!;
  }

  @override
  bool get wantKeepAlive => true;
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
  StreamController<bool> lockStream = StreamController<bool>.broadcast();
  StreamController<Map<String, Marker>> markerStream =
      StreamController<Map<String, Marker>>();

  /// This Displays the users pfp that are in the session
  /// Creates a row of profile picture widgets with optional member count overflow display.
  ///
  /// [memberNames] - List of member names to be displayed.
  /// [numOfPFPs] - Maximum number of profile pictures to display.
  /// [memberUIDs] - List of user IDs corresponding to the members.
  ///
  /// Returns:
  /// A `SizedBox` containing a horizontal `ListView` of profile pictures. If the
  /// number of members exceeds [numOfPFPs], the last visible item will display a
  /// "+X" overflow indicator, where X is the number of additional members.
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

  /// Adds a session to the map and fetches its owner's profile picture.
  ///
  /// [sessionID] - Unique identifier for the session.
  /// [json] - JSON object containing session data.
  ///
  /// Functionality:
  /// - Parses the session data from the [json] input.
  /// - Checks if the session passes filter criteria and contains valid coordinates.
  /// - Adds a map marker for the session and retrieves the owner's profile picture.
  /// - Handles errors gracefully by skipping problematic entries.
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

  /// Fetches and sets the owner's profile picture as a custom map marker.
  ///
  /// [json] - JSON object containing session and user data.
  /// [session] - The session object associated with the marker.
  /// [sessionID] - Unique identifier for the session.
  ///
  /// Functionality:
  /// - Retrieves the owner's UID and profile picture path.
  /// - Attempts to load the profile picture as a custom marker icon.
  /// - Falls back to the default marker icon if the profile picture is unavailable or an error occurs.
  /// - Updates the session's map marker with the appropriate custom icon.
  Future<void> addOwnerPfp(
      dynamic json, Session session, String sessionID) async {
    try {
      final LatLng sessionLocation =
          LatLng(session.latitude!, session.longitude!);

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

  /// Adds or modifies a marker on the map and updates the UI via a stream.
  ///
  /// [id] - Unique identifier for the marker.
  /// [location] - The geographical location (latitude and longitude) for the marker.
  /// [session] - The session associated with the marker, used to build custom info window content.
  /// [pfpIcon] - The icon for the marker, typically the owner's profile picture.
  /// [sessionID] - Unique identifier for the session associated with the marker.
  ///
  /// Functionality:
  /// - Creates or updates a marker at the specified location with the provided icon.
  /// - Displays a custom info window when the marker is tapped, using the session data.
  /// - Updates the stream with the modified markers to trigger a UI update.
  void _addMarker(String id, LatLng location, Session session,
      BitmapDescriptor pfpIcon, String sessionID) {
    final MarkerId markerId = MarkerId(id);
    final Marker marker = Marker(
      markerId: markerId,
      position: location,
      onTap: () {
        customInfoWindowController.addInfoWindow!(
            _buildCustomInfoWindow(session, sessionID), location);
      },
      icon: pfpIcon,
    );
    markers[id] = marker;
    markerStream.add(markers);
  }

  /// Builds a custom information window to display session details when a marker is tapped.
  ///
  /// [session] - The session associated with the marker.
  /// [sessionID] - Unique identifier for the session to fetch data.
  ///
  /// Functionality:
  /// - Uses two nested `StreamBuilder`s to listen for real-time updates from session data and lock status.
  /// - Displays session title, description, time, and location description.
  /// - Shows the owner's profile picture or a default image if unavailable.
  /// - Displays a list of users in the session with profile pictures (limited to 5).
  /// - Includes buttons for joining or leaving the session and expanding the session details.
  /// - Handles error cases by returning an empty widget when necessary.
  Widget _buildCustomInfoWindow(Session session, String sessionID) {
    return StreamBuilder(
        stream: lockStream.stream,
        builder: (context, snapshot) {
          return StreamBuilder(
            stream: widget.controller.sessionRef.child(sessionID).onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const SizedBox
                    .shrink(); // Display nothing if there’s no data.
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
                              stream: widget.controller
                                  .pfpRef(ownerUID)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                return FutureBuilder(
                                    future: widget.controller
                                        .getProfilePictureByUID(ownerUID, true),
                                    builder: (context, snapshot) {
                                      if (snapshot.data != null) {
                                        return CachedProfilePicture(
                                            name: ownerName,
                                            radius: 30,
                                            fontSize: 30,
                                            imageUrl: snapshot.data);
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: Image.asset(
                                            'assets/images/lamp_logo.png',
                                            width:
                                                60, // Adjust the width and height
                                            height: 70,
                                            fit: BoxFit
                                                .contain, // Ensures the image fits within the specified dimensions
                                          ),
                                        );
                                      }
                                    });
                              })
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
        });
  }

  /// Loads an image from the asset bundle, resizes it to the specified width,
  /// and returns the image as a [Uint8List] in PNG format.
  ///
  /// This function is typically used for loading and resizing images to be used
  /// as icons or markers on a map.
  ///
  /// [path] - The path to the image asset.
  /// [width] - The target width to which the image will be resized.
  ///
  /// Returns:
  /// - A [Future<Uint8List>] representing the image data in PNG format.
  Future<Uint8List> getBytesFromAsset(
      {required String path, required int width}) async {
    // Load the image data from the asset
    final ByteData _data = await rootBundle.load(path);

    // Instantiate an image codec to decode the image, resizing to the specified width
    final ui.Codec _codec = await ui
        .instantiateImageCodec(_data.buffer.asUint8List(), targetWidth: width);

    // Retrieve the next frame from the codec (the resized image)
    final ui.FrameInfo _fi = await _codec.getNextFrame();

    // Convert the image to byte data in PNG format
    final Uint8List _bytes =
        (await _fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();

    // Return the image as a Uint8List in PNG format
    return _bytes;
  }

  /// Loads an image from the network, resizes it to the specified width,
  /// and returns a circular version of the image as a [Uint8List] in PNG format.
  ///
  /// This function downloads the image from the provided URL, processes it to
  /// create a circular mask, and returns the image as a [Uint8List] suitable for use
  /// as an icon or marker in Flutter widgets.
  ///
  /// [imageUrl] - The URL of the image to be loaded.
  /// [width] - The target width and height of the circular image.
  ///
  /// Returns:
  /// - A [Future<Uint8List?>] representing the circular image in PNG format.
  ///   If the image could not be loaded, returns `null`.
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

  // Future<Map<String, double>?> getInstitutionLatLng(String place) async {
  //   PlacesSearchResponse response = await places.searchByText(place);
  //   if (response.isOkay) {
  //     final location = response.results[0].geometry!.location;
  //     return {
  //       'latitude': location.lat,
  //       'longitude': location.lng,
  //     };
  //   } else {
  //     print('Failed to load data: ${response.errorMessage}');
  //     return null;
  //   }
  // }

  /// Retrieves the user's current position, checks for location service and permission status,
  /// and updates the camera position on a Google Map based on the user's location.
  ///
  /// This method first checks whether location services are enabled. If location services
  /// are disabled, it returns an error. Then, it checks the current location permission status.
  /// If the permission is denied, it requests permission from the user. If permission is
  /// permanently denied, an error is returned. Finally, the method retrieves the user's current
  /// location and updates the map camera to center on the user's position.
  ///
  /// Returns:
  /// - A [Future.error] with an appropriate error message if any location-related issue occurs.
  /// - Updates the Google Map camera if location is successfully obtained.
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

  // /// Centers the Google Map camera on the user's home institution.
  // void goToHomeSchool() {
  //   getInstitutionLatLng(widget.controller.studentInstitution).then((latLng) {
  //     if (latLng != null) {
  //       googleMapController.animateCamera(
  //         CameraUpdate.newCameraPosition(
  //           CameraPosition(
  //             target: LatLng(latLng['latitude']!, latLng['longitude']!),
  //             zoom: 15,
  //           ),
  //         ),
  //       );
  //     } else {
  //       print('Failed to get institution location.');
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Update map when changing schools
    return StreamBuilder<DatabaseEvent>(
        stream: widget.controller.profileRef.onValue,
        builder: (profCon, profSnap) {
          // goToHomeSchool();
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

  /// Builds the map user interface (UI) with Google Map, custom info window, and action buttons.
  ///
  /// This widget creates a stack containing a [GoogleMap] and overlay widgets, including:
  /// - A [CustomInfoWindow] that displays information about the session when tapped.
  /// - A button to open a modal bottom sheet for filtering sessions.
  /// - A button to center the map to the user's current position.
  /// - A button to navigate to the user's home school location.
  ///
  /// Parameters:
  /// - [context] - The build context for widget tree.
  /// - [markers] - A set of markers to be displayed on the map.
  ///
  /// Returns:
  /// - A [Stack] widget containing the map UI and overlay buttons.
  Stack mapUI(BuildContext context, Set<Marker> markers) {
    return Stack(
      children: <Widget>[
        currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: currentLocation!,
                padding: const EdgeInsets.only(bottom: 80),
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
          top: 8,
          left: 15,
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
              width: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 22, 22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Filter: ',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.filter_list, color: Colors.blue),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 55,
          left: 15,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              currentPosition();
            },
            child: SizedBox(
              height: 40,
              width: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 22, 22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Locate: ',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(width: 3),
                    Transform.rotate(
                      angle: 0.75,
                      child: const Icon(Icons.navigation_outlined,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Positioned(
        //   top: 8,
        //   right: 15,
        //   child: GestureDetector(
        //     behavior: HitTestBehavior.translucent,
        //     onTap: () {
        //       goToHomeSchool();
        //     },
        //     child: SizedBox(
        //       height: 40,
        //       width: 100,
        //       child: Container(
        //         decoration: BoxDecoration(
        //           color: const Color.fromARGB(255, 22, 22, 22),
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //         child: const Row(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             Text(
        //               'School: ',
        //               style: TextStyle(color: Colors.white, fontSize: 15),
        //             ),
        //             SizedBox(width: 3),
        //             Icon(Icons.school_outlined, color: Colors.red),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  /// Builds a button for joining or leaving a session, with a dynamic appearance and behavior based on the session state.
  ///
  /// The button's appearance changes depending on the availability of seats and whether the user is already in the session.
  /// It also handles the logic for joining or leaving the session, or deleting the session if the user owns it.
  ///
  /// Parameters:
  /// - [key] - The session key.
  /// - [session] - The session object containing details such as available and taken seats.
  /// - [sessionID] - The ID of the current session.
  ///
  /// Returns:
  /// - A [Padding] widget containing the button with the necessary interaction and state management.
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
                          }).then((val) => lockStream.sink.add(lock.inLock));
                        },
                  child: Text(key == controller.student.ownedSessionKey
                      ? "Delete"
                      : buttonText),
                ),
        ),
      ),
    );
  }

  /// Builds a button that navigates to an expanded session view when pressed.
  ///
  /// The button appears with a blue background and a rounded shape. When pressed, it navigates the user to a page
  /// where they can view more details about the session. This is used to expand the session details into a new screen.
  ///
  /// Parameters:
  /// - [key] - The session key (currently not used in the function, but can be used for further logic).
  /// - [session] - The session object, which contains information about the session (currently not used directly, but could be in the future).
  /// - [sessionID] - The ID of the session, passed to the `ExpandedSessionPage` for further processing.
  ///
  /// Returns:
  /// - A [Padding] widget containing a button that, when pressed, navigates to an expanded session view.
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
