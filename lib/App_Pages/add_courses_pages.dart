import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page for users to input their classes to their profile
/// Basically a copy of location filter page but with input validation
class AddCoursesPage extends StatefulWidget{
  const AddCoursesPage(
    this.courses,
    {super.key}
  );
  final List<dynamic> courses;

  @override
  State<AddCoursesPage> createState() => _AddCoursesPage();
}

class _AddCoursesPage extends State<AddCoursesPage> {
  TextEditingController courseController = TextEditingController();
  List<Widget> bubbleCourses = [];
  List<dynamic> textCourses = [];
  FocusNode focus = FocusNode();
  RegExp courseRegEx = RegExp(r'^([a-zA-Z]{2,5} [0-9]{4})$');
  bool invalidInput = false;


  @override
  void initState() {
    super.initState();
    // Keep previous location filters
    textCourses.addAll(widget.courses);
    for (var text in textCourses){
      bubbleCourses.add(filterBubble(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop){
            return;
          }
          Navigator.of(context).pop(textCourses);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and back button
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        flex:1,
                        child: GestureDetector(
                          onTap:() => Navigator.of(context).maybePop(textCourses),
                          child: const Icon(Icons.arrow_back)
                        ),
                      ),
                      const Expanded(
                        flex: 5,
                        child: Text(
                          "Add your courses",
                          style: TextStyle(
                            fontSize: 24
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Text input for users to type in their courses
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.only(left:4.0),
                    child: TextField(
                      maxLength: 9,
                      autofocus: true,
                      controller: courseController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9 ]")), // Allow only letters, numbers, and spaces
                      ],
                      focusNode: focus,
                      onSubmitted: (value) {
                        value = value.toUpperCase().trim();
                        bool isMatch = courseRegEx.hasMatch(value);
                        if(isMatch){
                          addCourse(value);
                        }
                        else{
                          TextSelection cursor = courseController.selection;
                          focus.requestFocus();
                          courseController.selection = cursor;
                        }
                        setState((){
                          invalidInput = !isMatch;
                        });
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            String value = courseController.text.toUpperCase().trim();
                            bool isMatch = courseRegEx.hasMatch(value);
                            if(isMatch){
                              addCourse(value);
                            }
                            else{
                              TextSelection cursor = courseController.selection;
                              focus.requestFocus();
                              courseController.selection = cursor;
                            }
                            setState((){
                              invalidInput = !isMatch;
                            });
                          },
                          child: const Icon(Icons.add)
                        ),
                        hintText: "CS 4500, MATH 3220, MUSC 1236...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        counterText: "",
                        helperText: invalidInput ? "Invalid Input for course" : "",
                        helperStyle: const TextStyle(color: Colors.red)
                      ),
                    ),
                  ),
                ),
              ),
              // List of courses the user is in
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap(
                    children: bubbleCourses
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI method that creates a bubble given a text with the option to remove the 
  // course from the list by clicking on it
  GestureDetector filterBubble(String text) {
    return GestureDetector(
      onTap: (){
        setState((){
          // Remove from list
          var index = textCourses.indexOf(text);
          textCourses.removeAt(index);
          bubbleCourses.removeAt(index);
        });
      },  
      child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: const Color.fromARGB(255, 65, 65, 65),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(text),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.close)
            ),
        ],
      )
      )
    );
  }
  
  // Helper method to add user's text input into the course list
  addCourse(String value) {
    setState((){
      var val = value.trim();
      if (val.isEmpty){
        return;
      }
      if(!textCourses.contains(val)){
        textCourses.add(val);
        bubbleCourses.add(filterBubble(val));
      }
      courseController.clear();
      focus.requestFocus();
    });
  }

}