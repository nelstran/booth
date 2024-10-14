import 'package:flutter/material.dart';

class FilterUI extends StatefulWidget {
  const FilterUI(
    this.filters,
    {super.key}
  );
  final Map filters;
  @override
  State<StatefulWidget> createState() => _FilterUI();
  
}
class _FilterUI extends State<FilterUI> {
  // Change values here 
  Map<String, dynamic> defaultValues = {
    "currMinSliderValue": 0.0,
    "currMinString": 'Any',
    "minimumMaxValue": 25,
    "currMaxSliderValue": 25.0,
    "currMaxString": 'Any',
    "maximumMinValue": 25,
    "hideFull": false,
  };

  Map currentFilters = {};

  // late double currMinSliderValue;
  // late String currMinString;
  // late int minimumMaxValue;
  // late double currMaxSliderValue;
  // late String currMaxString;
  // late int maximumMinValue;
  // late bool hideFull;

  Map currentValues = {};

  @override
  void initState() {
    super.initState();
    resetValues();
    currentFilters = widget.filters;
    currentValues.addAll(widget.filters);
  }

  void resetValues(){
    setState((){
      currentValues.addAll(defaultValues);
    });
    currentFilters.clear();
  }

  void setMinVal(value){
    setState((){
      currentValues['currMinSliderValue'] = value;
    });
    int rounded = currentValues['currMinSliderValue'].round();
    if (rounded == currentValues['minimumMaxValue']){
      currentValues['currMinString'] = '${currentValues['minimumMaxValue']}+';
    }
    else if (rounded == 0){
      currentValues['currMinString'] = 'Any';
    }
    else {
      currentValues['currMinString'] = currentValues['currMinSliderValue'].round().toString();
    }
  }

  void setMaxVal(value){
    setState((){
      currentValues['currMaxSliderValue'] = value;
    });
    int rounded = currentValues['currMaxSliderValue'].round();
    if (rounded == currentValues['maximumMinValue']){
      currentValues['currMaxString'] = '${currentValues['maximumMinValue']}+';
    }
    else {
      currentValues['currMaxString'] = currentValues['currMaxSliderValue'].round().toString();
    }
  }
  
  void setFull(value){
    setState(() {
      currentValues['hideFull'] = value!;
      setCurrentValue('hideFull', value);
    });
  }

  void setCurrentValue(key, value){
    if (value != defaultValues[key]){
      currentFilters[key] = value;
    }
    else{
      currentFilters.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => resetValues(),
                child: const Padding(
                  padding: EdgeInsets.only(left: 24, bottom: 24.0),
                  child: Text(
                    "Reset",
                    style: TextStyle(
                      color: Colors.blue
                    ),),
                )
              ),
            ),
            const Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  "Filter Options",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ),
            ),
          ],
        ),
        // Hide full sessions filter
        Card(
          color:const  Color.fromARGB(255, 34, 34, 34),
          shape:const  RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0)
            )
          ),
          child: ListTile(
            onTap: (){
              setFull(!currentValues['hideFull']);
            },
            contentPadding: const EdgeInsets.only(left: 16, right: 8),
            title: const Text("Hide full sessions"),
            trailing: Checkbox(
              value: currentValues['hideFull'], 
              activeColor: const Color.fromARGB(255, 18, 93, 168),
              onChanged: (value){
                setFull(value);
              }
            ),
          )
        ),
        // Minimum seats available filter
        Card(
          color:const  Color.fromARGB(255, 34, 34, 34),
          shape:const  RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0)
            )
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12, right: 22, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Minimum seats available",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 17
                      )
                    ),
                    Text(
                      currentValues['currMinString'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                      )
                    )
                  ],
                ),
              ),
              Slider(
                value: currentValues['currMinSliderValue'], 
                max: currentValues['minimumMaxValue'].toDouble(),
                activeColor: const Color.fromARGB(255, 18, 93, 168),
                divisions: null,
                onChanged: (value){
                  setMinVal(value);
                }
              )
            ]
          )
        ),
        // Maximum lobby size filter
        Card(
          color:const  Color.fromARGB(255, 34, 34, 34),
          shape:const  RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0)
            )
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12, right: 22, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Maximum lobby size",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 17
                      )
                    ),
                    Text(
                      currentValues['currMaxString'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                      )
                    )
                  ],
                ),
              ),
              Slider(
                value: currentValues['currMaxSliderValue'], 
                max: currentValues['maximumMinValue'].toDouble(),
                min: 1,
                activeColor: const Color.fromARGB(255, 18, 93, 168),
                divisions: null,
                onChanged: (value){
                  setMaxVal(value);
                }
              )
            ]
          )
        ),
        // Location filter
        Card(
          color:const  Color.fromARGB(255, 34, 34, 34),
          shape:const  RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0)
            )
          ),
          child:ListTile(
            title: const Text("Locations"),
            trailing: const Icon(Icons.add),
            onTap: (){},
          ),
        ),
        // Subject filter
        Card(
          color:const  Color.fromARGB(255, 34, 34, 34),
          shape:const  RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0)
            )
          ),
          child:ListTile(
            title: const Text("Subject"),
            trailing: const Icon(Icons.add),
            onTap: (){},
          )
        ),
        // Apply filters
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (){
                Navigator.of(context).pop(currentFilters);
              }, 
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0)
                  )
                )
              ),
              child: Text("Apply ${currentFilters.isEmpty ? '' : '${currentFilters.length} '}filter(s)"),
            ),
          ),
        )
      ],
    );
  }
  
}