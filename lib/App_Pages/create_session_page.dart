// Create textboxes for user to fill in (can use TextBox from UI components)
// Should there be required fields that must be filled before they can create a session?
// If so, make sure required fields are filled in

// After all details have been filled, they need to be stored in firebase (this is done in Database -> firebase.dart)
// Should we create a booth session class this way each booth session is an object
// that has all of these details as instance variables, and then can easily be displayed
// in each tile in the session home page?

// Create a button to add the session to the session home page (can use Button from UI components)
// Once this button is pressed, go to the session home page
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
  final Session? session;
  final bool isEditing;
  const CreateSessionPage(this.controller, {this.session, this.isEditing = false, super.key});

  @override
  State<StatefulWidget> createState() {
    return _CreateSessionPageState();
  }
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _time;
  String? _locationDescription;
  int? _seatsAvailable;
  String? _subject;
  bool _isPublic = true;
  bool _shareLocation = false;
  String? _currentAddress;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      // Prepopulate fields with session values if editing
      _title = widget.session!.title;
      _description = widget.session!.description;
      _time = widget.session!.time;
      _locationDescription = widget.session!.locationDescription;
      _seatsAvailable = widget.session!.seatsAvailable;
      _subject = widget.session!.subject;
      _isPublic = widget.session!.isPublic;
      _currentAddress = widget.session!.address;
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
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
      if (widget.isEditing) {
        await _updateSession();
      } else {
        await _createSession();
      }
    } catch (e) {
      // Handle error
      debugPrint(e.toString());
    } finally {
      Navigator.pop(context);
    }
  }

  Future<void> _updateSession() async {
    widget.controller.db.updateSession(widget.session!.key, {
      'title': _title,
      'description': _description,
      'time': _time,
      'locationDescription': _locationDescription,
      'seatsAvailable': _seatsAvailable,
      'subject': _subject,
      'isPublic': _isPublic,
      'latitude': _currentPosition?.latitude,
      'longitude': _currentPosition?.longitude,
      'address': _currentAddress,
    });
    Navigator.pop(context);
  }

  Future<void> _createSession() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;

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

    _formKey .currentState!.save();

    final boothSession = Session(
      title: _title ?? '',
      description: _description ?? '',
      time: _time ?? '',
      locationDescription: _locationDescription ?? '',
      seatsAvailable: _seatsAvailable ?? 0,
      subject: _subject ?? '',
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
    widget.controller.addSession(boothSession, student);

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController classController = TextEditingController();
    classController.text = _subject ?? "";
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
              Text(widget.session != null ? 'Edit Session' : 'Create Session',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _title = value,
                initialValue: _title, 
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) => _description = value,
                initialValue: _description, 
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Time'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a time';
                  }
                  return null;
                },
                onSaved: (value) => _time = value,
                initialValue: _time, 
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                maxLength: 40,
                decoration:
                    const InputDecoration(labelText: 'Location Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location description';
                  }
                  return null;
                },
                onSaved: (value) => _locationDescription = value,
                initialValue: _locationDescription, 
              ),
              const SizedBox(height: 8.0),
              TextFormField(
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
                onSaved: (value) => _seatsAvailable = int.tryParse(value!),
                initialValue: _seatsAvailable?.toString(), 
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: classController,
                inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                  ],
                  maxLength: 5,
                decoration: const InputDecoration(labelText: 'Class'),
                onChanged: (value) {
                    classController.text = value.toUpperCase();
                  },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a class';
                  }
                  return null;
                },
                onSaved: (value) => _subject = value,
                // initialValue: _subject, 
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
                onChanged: (bool value) {
                  setState(() {
                    _shareLocation = value;
                  });
                },
                subtitle:
                    const Text('Allow your Booth to be visible on the map!'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _handleSessionCreation();
                  }
                },
                style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFF0d4073))),
                child: Text(widget.session != null ? 'Update Session' : 'Create Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
