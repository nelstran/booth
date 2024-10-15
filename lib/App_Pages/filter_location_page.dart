import 'package:flutter/material.dart';

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
  TextEditingController locationField = TextEditingController();
  List<Widget> bubbleFilters = [];
  List<dynamic> textFilters = [];
  FocusNode focus = FocusNode();

  @override
  void initState() {
    super.initState();
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
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
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
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: locationField,
                  focusNode: focus,
                  onSubmitted: (value) => setState((){
                    var val = value.trim();
                    if (val.isEmpty){
                      return;
                    }
                    textFilters.add(val);
                    locationField.clear();
                    bubbleFilters.add(filterBubble(val));
                    focus.requestFocus();
                  }),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    suffixIcon: GestureDetector(
                      onTap: (){
                        setState((){
                          var val = locationField.text.trim();
                          if (val.isEmpty) {
                            return;
                          }
                          textFilters.add(val);
                          bubbleFilters.add(filterBubble(val));
                          locationField.clear();
                          focus.requestFocus();
                        });
                    },
                      child: const Icon(Icons.add)
                    ),
                    hintText: "Library, Cafe, Patio...",
                    hintStyle: const TextStyle(color: Colors.grey)
                    
                  ),
                ),
              ),
            ),
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

  GestureDetector filterBubble(String text) {
    return GestureDetector(
      onTap: (){
        setState((){
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

}