import 'package:flutter/material.dart';

/// This filter location page comes pops up from the filter UI, 
/// this allows users to input any list of locations that they prefer to 
/// study in
class FilterLocationPage extends StatefulWidget{
  const FilterLocationPage(
    this.filters,
    {super.key}
  );
  final List<dynamic> filters;

  @override
  State<FilterLocationPage> createState() => _FilterLocationPage();
}

class _FilterLocationPage extends State<FilterLocationPage> {
  TextEditingController locationController = TextEditingController();
  List<Widget> bubbleFilters = [];
  List<dynamic> textFilters = [];
  FocusNode focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Keep previous location filters
    textFilters.addAll(widget.filters);
    for (var text in textFilters){
      bubbleFilters.add(filterBubble(text));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
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
                        onTap:() => Navigator.of(context).pop(textFilters),
                        child: const Icon(Icons.arrow_back)
                      ),
                    ),
                    const Expanded(
                      flex: 5,
                      child: Text(
                        "Add locations",
                        style: TextStyle(
                          fontSize: 24
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Text input for users to type in their locations
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  controller: locationController,
                  focusNode: focus,
                  onSubmitted: (value) => addLocation(value),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () => addLocation(locationController.text),
                      child: const Icon(Icons.add)
                    ),
                    hintText: "Library, Cafe, Patio...",
                    hintStyle: const TextStyle(color: Colors.grey)
                    
                  ),
                ),
              ),
            ),
            // List of locations the user prefers to be in
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  children: bubbleFilters
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  // UI method that creates a bubble given a text with the option to remove the 
  // location from the filter by clicking on it
  GestureDetector filterBubble(String text) {
    return GestureDetector(
      onTap: (){
        setState((){
          // Remove from filter
          var index = textFilters.indexOf(text);
          textFilters.removeAt(index);
          bubbleFilters.removeAt(index);
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
  
  // Helper method to add user's text input into the filter list
  addLocation(String value) {
    setState((){
      var val = value.trim();
      if (val.isEmpty){
        return;
      }
      textFilters.add(val);
      locationController.clear();
      bubbleFilters.add(filterBubble(val));
      focus.requestFocus();
    });
  }

}