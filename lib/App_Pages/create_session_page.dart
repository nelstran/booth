// Create textboxes for user to fill in (can use TextBox from UI components)
// Should there be required fields that must be filled before they can create a session?
// If so, make sure required fields are filled in

// After all details have been filled, they need to be stored in firebase (this is done in Database -> firebase.dart)
// Should we create a booth session class this way each booth session is an object
// that has all of these details as instance variables, and then can easily be displayed
// in each tile in the session home page?

// Create a button to add the session to the session home page (can use Button from UI components)
// Once this button is pressed, go to the session home page
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/session_extension.dart';
import 'package:Booth/MVC/session_model.dart';
import 'package:Booth/MVC/student_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class CreateSessionPage extends StatefulWidget {
  final BoothController controller;
  final String? sessionKey;
  const CreateSessionPage(this.controller, {this.sessionKey, super.key});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();

  String? _currentAddress;
  Position? _currentPosition;
  bool _isPublic = true;
  bool _shareLocation = false;
  File? sessionFile;
  bool newImage = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _currAddrController = TextEditingController();

  bool showingSnack = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    sessionFile = null;
    if (widget.sessionKey != null) {
      isEditing = true;
      widget.controller.getSession(widget.sessionKey!).then((value) {
        if (value.isEmpty) {
          return;
        }
        Session session = Session.fromJson(value);
        // Prepopulate fields with session values if editing
        setState(() {
          _titleController.text = session.title;
          _descController.text = session.description;
          _timeController.text = session.time;
          _classController.text = session.subject;
          _locationController.text = session.locationDescription;
          _seatsController.text = session.seatsAvailable.toString();
          _classController.text = session.subject;
          _isPublic = session.isPublic;
          _currAddrController.text = session.address ?? '';
          _shareLocation = session.address != null;
        });
        if (session.imageURL != null){
          fetchImage(session.imageURL!);
        }
      });
    }
  }

  Future<void> fetchImage(String url) async {
    final cacheManager = DefaultCacheManager();
      // No need to check if url is valid since we're in a try/catch
      final file = await cacheManager.getSingleFile(url);
      // final fileBytes = await file.readAsBytes();
      setState((){
        sessionFile = file;
      });
  }

  // Method to display snackbar warning while also preventing it from
  // being loaded multiple times when users spam the toggle
  void displayWarning(String text) {
    if (showingSnack) {
      return;
    }
    showingSnack = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)))
        .closed
        .then((reason) {
      showingSnack = false;
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      displayWarning(
          'Location services are disabled. Please enable the services');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        displayWarning('Location permissions are denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      displayWarning(
          'Please enable location permissions in your phone\'s settings');
      return false;
    }
    return true;
  }

  Future<String?> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        return address;
      }
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
    // If no address is found
    return null;
  }

  Future<void> _handleSessionCreation() async {
    // Loading circle
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      if (isEditing) {
        await _updateSession();
      } else {
        await _createSession();
      }
      // Pop loading circle
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      debugPrint(e.toString());
    } finally {
      // Pop current screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _updateSession() async {
    String? imageURL;
    if (_shareLocation) {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((Position position) async {
        setState(() => _currentPosition = position);
        String? address = await _getAddressFromLatLng(position);

        if (address != null) {
          setState(() => _currentAddress = address);
        }
      }).catchError((e) {
        debugPrint(e);
      });
    }
    if (newImage && sessionFile != null){
      try{
        imageURL = await widget.controller.uploadSessionPicture(sessionFile!, widget.sessionKey!);
      }
      catch (e){
        // Skip
      }
    }

    Map<String, Object?> values = {
      'title': _titleController.text,
      'description': _descController.text,
      'time': _timeController.text,
      'locationDescription': _locationController.text,
      'seatsAvailable': int.parse(_seatsController.text),
      'subject': _classController.text,
      'isPublic': _isPublic,
    };
    // Remove location if users no longer want to share location
    values.addAll({
      'latitude': _shareLocation ? _currentPosition?.latitude : null,
      'longitude': _shareLocation ? _currentPosition?.longitude : null,
      'address': _shareLocation ? _currentAddress : null,
    });
    // Update image, delete image if user removes it
    if (newImage){
      values.addAll({
        'imageURL': imageURL
      });

      if(sessionFile == null){
        widget.controller.deleteSessionPicture(widget.sessionKey!);
      }
    }
    await widget.controller.editSession(widget.sessionKey!, values);
  }

  Future<void> _createSession() async {
    if (_shareLocation) {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((Position position) async {
        setState(() => _currentPosition = position);
        String? address = await _getAddressFromLatLng(position);

        if (address != null) {
          setState(() => _currentAddress = address);
        }
      }).catchError((e) {
        debugPrint(e);
      });
    }

    _formKey.currentState!.save();

    final boothSession = Session(
      title: _titleController.text,
      description: _descController.text,
      time: _timeController.text,
      locationDescription: _locationController.text,
      seatsAvailable: int.parse(_seatsController.text),
      subject: _classController.text,
      isPublic: _isPublic,
      field: "field",
      level: 1000,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      address: _currentAddress,
    );

    Student student = widget.controller.student;
    if (student.session != "") {
      await widget.controller
          .removeUserFromSession(student.session, student.sessionKey);
    }
    await widget.controller.addSession(boothSession, student, file: sessionFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Session' : 'Create Session',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // const SizedBox(height: 16.0),
              TextFormField(
                controller: _titleController,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 8.0),
              TextFormField(
                controller: _descController,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 8.0),
              TextFormField(
                canRequestFocus: false,
                onTap: (){
                  // Try to format time, if it is formatted wrong do current time
                  try{
                    String time = _timeController.text;
                    // Split "H:MM AA - H:MM AA"
                    List<String> times = time.split(" - ");

                    // Get hours and times
                    List<String> start = times[0].split(":");
                    String startAMPM = start[1].split(" ")[1];
                    List<String> end = times[1].split(":");
                    String endAMPM = end[1].split(" ")[1];

                    TimeOfDay startTime = TimeOfDay(
                      // Super confusing but if its PM add 12 hours since TimeOfDay works on 24 hr time cycle
                      hour: int.parse(start[0]) + (startAMPM == "PM" ? 12 : 0),
                      minute: int.parse(start[1].substring(0, 2)) 
                      
                    );

                    TimeOfDay endTime = TimeOfDay(
                      hour: int.parse(end[0]) + (endAMPM == "PM" ? 12 : 0),
                      minute: int.parse(end[1].substring(0, 2))
                    );
                    // Open up time picker with the given time
                    selectTimeRange(startTime: startTime, endTime: endTime);
                  }
                  catch (e){
                    selectTimeRange();
                  }
                  },
                readOnly: true,
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a time';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 8.0),
              TextFormField(
                controller: _locationController,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'Location Description',
                  suffix: GestureDetector(
                    onTap: (){
                      if (sessionFile == null){
                        openCamera();
                      }
                      else {
                        showPicture();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: sessionFile == null
                      ? const Icon(Icons.photo_camera)
                      : const Icon(Icons.photo_outlined),
                    )
                  )
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location description';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 8.0),
              TextFormField(
                controller: _seatsController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                ],
                maxLength: 3,
                decoration: const InputDecoration(labelText: 'Seats Available'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of seats available';
                  }
                  final seats = int.tryParse(value);
                  if (seats == null || seats <= 0) {
                    return 'Please enter a valid number of seats';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              // const SizedBox(height: 8.0),
              TextFormField(
                controller: _classController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                ],
                maxLength: 5,
                decoration: const InputDecoration(labelText: 'Class Abbreviation'),
                onChanged: (value) {
                  _classController.text = value.toUpperCase();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a class';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 8.0),
              DropdownButtonFormField<bool>(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value!;
                  });
                },
                items: const [
                  DropdownMenuItem<bool>(
                    value: true,
                    child: Text('Public'),
                  ),
                  DropdownMenuItem<bool>(
                    value: false,
                    child: Text('Private'),
                  ),
                ],
              ),
              // const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Share Location'),
                value: _shareLocation,
                onChanged: (bool value) async {
                  // Change UI then ask for permission
                  setState(() {
                    _shareLocation = value;
                  });

                  // Ask for permission when toggled on
                  var hasPermission = false;
                  if (value) {
                    hasPermission = await _handleLocationPermission();
                  }

                  setState(() {
                    _shareLocation = hasPermission;
                  });
                },
                subtitle:
                    const Text('Allow your Booth to be visible on the map!'),
              ),
              // const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  // TODO: fix crash
                  if (_formKey.currentState!.validate()) {
                    await _handleSessionCreation();
                  }
                },
                style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFF0d4073))),
                child: Text(isEditing ? 'Update Session' : 'Create Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom time picker to have the same color scheme as the Booth App
  Future<TimeOfDay?> customTimePicker({required TimeOfDay time, required String helpText, required String confirmText}) async {
    return await showTimePicker(
      helpText: helpText,
      confirmText: confirmText,
      context: context, 
      initialTime: time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(255, 19, 119, 201),
              secondary: Color.fromARGB(255, 19, 119, 201)
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Method to set up the start and end time of a session, if [startTime] and [endTime] are empty, use current time
  void selectTimeRange({TimeOfDay? startTime, TimeOfDay? endTime}) {
    var localizations = MaterialLocalizations.of(context);
    startTime = startTime ?? TimeOfDay.now();
    endTime = endTime ?? TimeOfDay.now();
    customTimePicker(
      time: startTime,
      helpText: "Select your start time",
      confirmText: "Set start"
    ).then((startValue){
      if(startValue == null){
        return;
      }
      customTimePicker(
      time: endTime!,
      helpText: "Select your end time",
      confirmText: "Set end"
      ).then((endValue){
        if(endValue == null){
          return;
        }
        _timeController.text = "${localizations.formatTimeOfDay(startValue)} - ${localizations.formatTimeOfDay(endValue)}";
      });
    });
  }

  /// Method to open the system camera for users to add to their 
  /// session upon creation
  Future<void> openCamera() async {
    // Get picture from camera
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.camera);
    bool? confirmPicture = false;

    // Confirm that the user wants this picture shown
    while(confirmPicture == false){
      if (file == null) return;
      confirmPicture = await previewPicture(file);

      if (confirmPicture == null){
        return;
      }
      if(!confirmPicture){
        file = await imagePicker.pickImage(source: ImageSource.camera);
      }
    }
    setState((){
      // We want to replace the image if users set a new one when editing
      newImage = true;
      sessionFile = File(file!.path);
    });
  }

  /// Method to preview the picture they just took, users can
  /// cancel, confirm, or retake the picture if needed
  Future<bool?> previewPicture(XFile file) async  {
    return await showDialog<bool?>(
      barrierDismissible: false,
      context: context,
      builder: (context){
        return AlertDialog(
          title: const Center(
            child: Text("Are you sure?"),
          ),
          titlePadding: const EdgeInsets.only(bottom: 8, top: 16),
          content: Image.file(File(file.path)),
          // content: CachedNetworkImage(imageUrl: sessionImg!),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 24),
          actions:[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero
                      ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context, false);
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0.0,
                        shadowColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero
                        ),
                    child: const Text(
                      "Retake",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      // padding: EdgeInsets.zero
                    ),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ]
        );
      }
    );
  }

  /// Method that shows the image the user is about to upload for 
  /// other users to see, it will give the option to delete it before 
  /// creating a session
  Future<void> showPicture() async  {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context){
        return AlertDialog(
          title: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Preview",
                style: TextStyle(fontSize: 30),
              ),
              Text(
                "(This image will be shared with other users)",
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              )
            ]
          ),
          titlePadding: const EdgeInsets.only(bottom: 8, top: 16,),
          content: Image.file(sessionFile!),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 24),
          actions:[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: (){
                      setState(() {
                        newImage = true;
                        sessionFile = null;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0.0,
                        shadowColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero
                        ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                    ),
                  child: const Text(
                    "Ok",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ]
        );
      }
    );
  }
}
