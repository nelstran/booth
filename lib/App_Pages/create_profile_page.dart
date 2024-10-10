import 'package:flutter/material.dart';
import 'package:flutter_application_1/App_Pages/institutions_page.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/profile_extension.dart';

class CreateProfilePage extends StatefulWidget {
  final BoothController controller;
  const CreateProfilePage(
    this.controller,
    {super.key}
  );

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
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

  Map<dynamic, dynamic> profile = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.controller.getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data is Map<dynamic, dynamic> && snapshot.data!.length > 1) {
            return createUI(snapshot.data);
          } else {
            return createUI();
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }
    );
  }

  Scaffold createUI([profile]) {
    var edit = profile !=
        null; // Page will change depending on if its a new profile or existing
    if (edit) {
      profile = profile as Map;
      edit = profile.isNotEmpty;
    }
    listOfCourses[0] = '${_courses.join(", ")} ';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(edit ? 'Edit Profile' : 'Create Profile')
      ),
      body: Column(
        children: [
          changeInstitutionUI(),
          profileForm(edit, profile),
        ],
      ),
    );
  }

  Form profileForm(bool edit, profile) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, top: 0, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16.0),
            TextFormField(
              initialValue: edit ? profile['name'] : null,
              decoration: const InputDecoration(labelText: 'Name'),
              onSaved: (value) => _name = value,
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              initialValue: edit ? profile['major'] : null,
              decoration: const InputDecoration(labelText: 'Major'),
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
              initialValue: edit ? profile['studyPref'] : null,
              decoration:
                  const InputDecoration(labelText: 'Study Preferences'),
              onSaved: (value) => _study_pref = value,
            ),
            TextFormField(
              initialValue: edit ? profile['availability'] : null,
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
                    "major": _major,
                    "year": _year,
                    "courses": _courses.asMap(),
                    "studyPref": _study_pref,
                    "availability": _availability
                };
                widget.controller.updateUserProfile(values);
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
  );
}

  ListTile changeInstitutionUI() {
    return ListTile(
      title: const Text(
        "Institution",
        style: TextStyle(
          fontSize: 13
        )),
      subtitle: Text(
        widget.controller.studentInstitution,
        style: const TextStyle(
          fontSize: 20
        )
      ),
      trailing: const SizedBox(
        width: 80,
        height: double.infinity,
        child: Row(
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Change",
              style: TextStyle(
                fontSize: 13
              )),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16)
          ]
        ),
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      tileColor: Colors.grey.shade900,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InstitutionsPage(widget.controller, 'Profile')
          )
        );
        setState((){});
      },
    );
  }
}
