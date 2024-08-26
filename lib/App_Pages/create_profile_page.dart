import 'package:flutter/material.dart';

class CreateProfilePage extends StatefulWidget {

  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {

  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _institution;
  String? _major;
  // Freshman, Sophomore, Junior, Senior
  String? _year;
  String? _courses;
  // Study Preferences
  String? _study_pref;
  String? _availability;

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Create Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name of your college/university';
                  }
                  return null;
                },
                onSaved: (value) => _institution = value,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
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
                items:const [
                  DropdownMenuItem(
                    value: "Freshman",
                    child: Text("Freshman")
                  ),
                  DropdownMenuItem(
                    value: "Sophomore",
                    child: Text("Sophomore")
                  ),
                  DropdownMenuItem(
                    value: "Junior",
                    child: Text("Junior")
                  ),
                  DropdownMenuItem(
                    value: "Senior",
                    child: Text("Senior")
                  ),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please make a selection';
                  }
                  return null;
                },
                onChanged: (value) => _year = value,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Courses'),
                onSaved: (value) => _courses = value,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Study Preferences'),
                onSaved: (value) => _study_pref = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Availability'),
                onSaved: (value) => _availability = value,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // TODO BACKEND:
                  // Add user details to database
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {return Colors.blue;}),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );

  }
}