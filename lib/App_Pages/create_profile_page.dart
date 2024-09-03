import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _institution;
  List<String> listOfInstitutions = <String>[
    "University of Utah",
    "Salt Lake Community College"
  ];
  String? _major;
  // Freshman, Sophomore, Junior, Senior
  String? _year;
  // String? _courses;

  // TESTING
  List<String?> _courses = <String>[];
  List<Object?> listOfCourses = <Object?>[
    null,
    "CS 2420",
    "CS 3500",
    "CS 3550",
    "CS 1410",
    "MATH 1000",
    "ENG 1010"
  ];

  // Study Preferences
  String? _study_pref;
  String? _availability;

  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  late BoothController controller = BoothController(_ref);
  Map<dynamic, dynamic> profile = {};

  @override
  Widget build(BuildContext context) {
    // Fetch user profile to start updating it
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    if (arguments.containsKey("controller")) {
      controller = arguments['controller'] as BoothController;
    }
    return FutureBuilder(
        future: arguments.containsKey("controller")
            ? controller.getUserProfile()
            : controller.fetchAccountInfo(arguments["user"]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data is Map<dynamic, dynamic>) {
              return createUI(snapshot.data);
            } else {
              return createUI();
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Scaffold createUI([profile]) {
    var edit = profile !=
        null; // Page will change depending on if its a new profile or existing
    profile = profile as Map;
    if (edit) {
      edit = profile.isNotEmpty;
    }
    listOfCourses[0] = '${_courses.join(", ")} ';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                edit ? 'Edit Profile' : 'Create Profile',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: edit ? profile['name'] : '',
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value,
              ),
              const SizedBox(height: 8.0),
              // TextFormField(
              //   decoration: const InputDecoration(labelText: 'Institution'),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter the name of your college/university';
              //     }
              //     return null;
              //   },
              //   onSaved: (value) => _institution = value,
              // ),

              // FOR TESTING
              DropdownButtonFormField(
                value: edit && profile.containsKey('institution')
                    ? profile['institution'] as String
                    : null,
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name of your college/university';
                  }
                  return null;
                },
                items: listOfInstitutions.map((String value) {
                  return DropdownMenuItem(value: value, child: Text(value));
                }).toList(),
                onSaved: (value) => _institution = value,
                onChanged: (value) => _institution = value,
              ),

              const SizedBox(height: 8.0),
              TextFormField(
                initialValue: edit ? profile['major'] : '',
                decoration: const InputDecoration(labelText: 'Major'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your major';
                  }
                  return null;
                },
                onSaved: (value) => _major = value,
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField(
                value: edit && profile.containsKey('year')
                    ? profile['year'] as String
                    : null,
                decoration: const InputDecoration(labelText: 'Year'),
                items: const [
                  DropdownMenuItem(value: "Freshman", child: Text("Freshman")),
                  DropdownMenuItem(
                      value: "Sophomore", child: Text("Sophomore")),
                  DropdownMenuItem(value: "Junior", child: Text("Junior")),
                  DropdownMenuItem(value: "Senior", child: Text("Senior")),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please make a selection';
                  }
                  return null;
                },
                onChanged: (value) => _year = value,
                onSaved: (value) => _year = value,
              ),
              const SizedBox(height: 8.0),
              // TextFormField(
              //   decoration: const InputDecoration(labelText: 'Courses'),
              //   onSaved: (value) => _courses = value,
              // ),

              // FOR TESTING
              DropdownButtonFormField(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Courses'),
                value: listOfCourses[0],
                menuMaxHeight: 250,
                icon: const Icon(Icons.add),
                validator: (value) {
                  if (value == null) {
                    return 'Please insert a course';
                  }
                  return null;
                },
                items: listOfCourses.whereType<String>().map((String value) {
                  if (listOfCourses.indexOf(value) == 0) {
                    return DropdownMenuItem<String>(
                        enabled: false, value: value, child: Text(value));
                  } else {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (value == listOfCourses[0]) {
                      return;
                    }
                    if (_courses.contains(value)) {
                      _courses.remove(value);
                    } else {
                      _courses.add(value.toString());
                    }
                    listOfCourses[0] = '${_courses.join(", ")} ';
                  });
                },
              ),

              const SizedBox(height: 8.0),
              TextFormField(
                initialValue: edit ? profile['studyPref'] : '',
                decoration:
                    const InputDecoration(labelText: 'Study Preferences'),
                onSaved: (value) => _study_pref = value,
              ),
              TextFormField(
                initialValue: edit ? profile['availability'] : '',
                decoration: const InputDecoration(labelText: 'Availability'),
                onSaved: (value) => _availability = value,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Add user details to database
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Map<String, Object?> values = {
                      "name": _name,
                      "institution": _institution,
                      "major": _major,
                      "year": _year,
                      "courses": _courses.asMap(),
                      "studyPref": _study_pref,
                      "availability": _availability
                    };
                    controller.updateUserProfile(values);
                    Navigator.pop(context);
                  }
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return Colors.blue;
                  }),
                ),
                child: const Text('Save'),
              ),
              const SizedBox(height: 16.0),
              if (!edit)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Skip for now",
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
