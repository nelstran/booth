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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/session_extension.dart';
import 'package:flutter_application_1/MVC/session_model.dart';
import 'package:flutter_application_1/MVC/student_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
    if (widget.sessionKey != null) {
      isEditing = true;
      widget.controller.getSession(widget.sessionKey!).then((value) {
        if (value.isEmpty){
          return;
        }
        Session session = Session.fromJson(value);
      // Prepopulate fields with session values if editing
      setState((){
        _titleController.text = session.title;
        _descController.text = session.description;
        _timeController.text = session.time;
        _classController.text = session.subject;
        _locationController.text = session.locationDescription;
        _seatsController.text = session.seatsAvailable.toString();
        _classController.text = session.subject;
        _isPublic = session.isPublic;
        _currAddrController.text = session.address ?? '';
      });
    });
    }
  }

  // Method to display snackbar warning while also preventing it from 
  // being loaded multiple times when users spam the toggle
  void displayWarning(String text){
    if(showingSnack) {
      return;
    }
    showingSnack = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text)
      )
    ).closed
    .then((reason){
      showingSnack = false;
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      displayWarning('Location services are disabled. Please enable the services');
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
      displayWarning('Please enable location permissions in your phone\'s settings');
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
      if (mounted){
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      debugPrint(e.toString());
    }
    finally{
      // Pop current screen
      if (mounted){
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _updateSession() async {
    Map<String, Object?> values = {
      'title': _titleController.text,
      'description': _descController.text,
      'time': _timeController.text,
      'locationDescription': _locationController.text,
      'seatsAvailable': int.parse(_seatsController.text),
      'subject': _classController.text,
      'isPublic': _isPublic,
      'latitude': _currentPosition?.latitude,
      'longitude': _currentPosition?.longitude,
      'address': _currentAddress,
    };
    await widget.controller.editSession(widget.sessionKey!, values);
  }

  Future<void> _createSession() async {
    if(_shareLocation){
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
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
      await widget.controller.removeUserFromSession(student.session, student.sessionKey);
    }
    await widget.controller.addSession(boothSession, student);
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
              Text(isEditing ? 'Edit Session' : 'Create Session',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
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
              const SizedBox(height: 8.0),
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
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _locationController,
                maxLength: 40,
                decoration:
                    const InputDecoration(labelText: 'Location Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8.0),
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
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _classController,
                inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                  ],
                  maxLength: 5,
                decoration: const InputDecoration(labelText: 'Class'),
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
              const SizedBox(height: 8.0),
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
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Share Location'),
                value: _shareLocation,
                onChanged: (bool value) async {
                  // Change UI then ask for permission
                  setState((){
                    _shareLocation = value;
                  });

                  // Ask for permission when toggled on
                  var hasPermission = false;
                  if (value){
                    hasPermission = await _handleLocationPermission();
                  }

                  setState(() {
                    _shareLocation = hasPermission;
                  });
                },
                subtitle:
                    const Text('Allow your Booth to be visible on the map!'),
              ),
              const SizedBox(height: 16.0),
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
}
