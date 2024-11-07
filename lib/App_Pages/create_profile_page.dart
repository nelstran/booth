import 'package:Booth/App_Pages/add_courses_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Booth/App_Pages/institutions_page.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/profile_extension.dart';
import 'package:flutter/services.dart';

class CreateProfilePage extends StatefulWidget {
  final BoothController controller;
  const CreateProfilePage(this.controller, {super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _coursesController = TextEditingController();
  final TextEditingController _studyPrefController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.controller.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data is Map<dynamic, dynamic> &&
                snapshot.data!.length > 1) {
              return createUI(snapshot.data);
            } else {
              return createUI();
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  bool setTextValues(Map<dynamic, dynamic> profile){
    String courses = "";
    if (profile.containsKey("courses")){
      try{
      courses = (profile["courses"] as List).join(", ");
      }
      catch (e){
        // Do nothing if it causes problems
      }
    }
    _nameController.text = profile["name"] ?? widget.controller.student.fullname;
    _majorController.text = profile["major"] ?? "";
    _yearController.text = profile["year"] ?? "";
    _coursesController.text = courses;
    _studyPrefController.text = profile["studyPref"] ?? "";
    _availabilityController.text = profile["availability"] ?? "";
    return profile.isNotEmpty;
  }
  Scaffold createUI([Map<dynamic, dynamic>? profile]) {
    bool edit = setTextValues(profile ?? {});
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(edit ? 'Edit Profile' : 'Create Profile')),
      body: Column(
        children: [
          changeInstitutionUI(),
          profileForm(edit),
        ],
      ),
    );
  }

  Form profileForm(bool edit) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, top: 0, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16.0),
            // Name Field
            TextFormField(
              inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
              ],
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Name'),
              controller: _nameController,
              validator: (value) {
                if (value == null){
                  return "Name cannot be empty";
                }
                value = value.trim();
                if (value.isEmpty){
                  return "Name cannot be empty";
                }
                return null;
              },
            ),
            const SizedBox(height: 8.0),
            // Major field
            TextFormField(
              inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
              ],
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Major'),
              controller: _majorController
            ),
            const SizedBox(height: 8.0),
            // Year field
            DropdownButtonFormField(
              value: _yearController.text == "" ? null : _yearController.text,
              decoration: const InputDecoration(labelText: 'Year'),
              items: const [
                DropdownMenuItem(value: "Freshman", child: Text("Freshman")),
                DropdownMenuItem(value: "Sophomore", child: Text("Sophomore")),
                DropdownMenuItem(value: "Junior", child: Text("Junior")),
                DropdownMenuItem(value: "Senior", child: Text("Senior")),
              ],
              onChanged: (value) => _yearController.text = value ?? "",
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Courses',
                suffixIcon: Icon(Icons.add)
                ),
              controller: _coursesController,
              onTap:(){
                List<String> courses = [];
                if (_coursesController.text.isNotEmpty){
                  courses = _coursesController.text.split(", ");
                }
                Navigator.of(context).push(
                  // Use Cupertino for slide transition (I'm too lazy to make my own)
                  CupertinoPageRoute(
                      builder: (_) => AddCoursesPage(courses)))
                    .then((value) {
                  if (value == null) {
                    return;
                  }
                  _coursesController.text = (value as List).join(", ");
                });
              }
            ),
            const SizedBox(height: 8.0),
            // Preferences Field
            TextFormField(
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Study Preferences'),
              controller: _studyPrefController,
            ),
            // Availability Field
            TextFormField(
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Availability'),
              controller: _availabilityController,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Map courses = {};
                if (_coursesController.text.isNotEmpty){
                  courses = _coursesController.text.split(", ").asMap();
                }
                // Add user details to database
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Map<String, Object?> values = {
                    "name": _nameController.text.trim(),
                    "major": _majorController.text.trim(),
                    "year": _yearController.text.trim(),
                    "courses": courses.isNotEmpty ? courses : null,
                    "studyPref": _studyPrefController.text.trim(),
                    "availability": _availabilityController.text.trim()
                  };
                  widget.controller.updateUserProfile(values);
                  widget.controller.updateUserEntry({"name": _nameController.text.trim()});
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
      title: const Text("Institution", style: TextStyle(fontSize: 13)),
      subtitle: Text(widget.controller.studentInstitution,
          style: const TextStyle(fontSize: 20)),
      trailing: const SizedBox(
        width: 80,
        height: double.infinity,
        child: Row(
            // mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Change", style: TextStyle(fontSize: 13)),
              Icon(Icons.arrow_forward_ios_rounded, size: 16)
            ]),
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      tileColor: Colors.grey.shade900,
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                InstitutionsPage(widget.controller, 'Profile')));
        setState(() {});
      },
    );
  }
}
