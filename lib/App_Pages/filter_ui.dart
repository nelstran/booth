import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Booth/App_Pages/filter_location_page.dart';

/// This UI helps users filter the long list of sessions by their preferences
/// Preferences include:
/// Hide full lobbies
/// Minimum available seats
/// Max lobby size
/// Locations
/// Class
class FilterUI extends StatefulWidget {
  const FilterUI(this.filters, {super.key});
  final Map filters;
  @override
  State<StatefulWidget> createState() => _FilterUI();
}

class _FilterUI extends State<FilterUI> {
  // Change default values here
  Map<String, dynamic> defaultValues = {
    "currMinSliderValue": 0.0,
    "currMinString": 'Any',
    "minimumMaxValue": 25,
    "currMaxSliderValue": 25.0,
    "currMaxString": 'Any',
    "maximumMinValue": 25,
    "hideFull": false,
    "locationFilters": [],
    "locationString": null,
    "classFilter": null,
  };

  // Filters that will be applied to sessions
  Map currentFilters = {};

  // Values that are displayed to keep filters consistent between navigation
  Map currentValues = {};

  @override
  void initState() {
    super.initState();
    // Reset everything to default
    resetValues();

    // Apply previous filters to keep consistency
    currentFilters.clear();
    currentFilters.addAll(widget.filters);
    currentValues.addAll(widget.filters);

    // Call functions to set proper string values
    setMinVal(currentValues['currMinSliderValue']);
    setMaxVal(currentValues['currMaxSliderValue']);
    setLocations(currentValues['locationFilters']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top UI
        Row(
          children: [
            // Reset filters
            Expanded(
              flex: 1,
              child: GestureDetector(
                  onTap: () => resetValues(),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 24, bottom: 24.0),
                    child: Text(
                      "Reset",
                      style: TextStyle(color: Colors.blue),
                    ),
                  )),
            ),
            // Title
            const Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  "Filter Options",
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
        // Hide full sessions filter
        hideFullUI(),
        // Minimum seats available filter
        minSeatsUI(),
        // Maximum lobby size filter
        maxSizeUI(),
        // Location filter
        locationUI(context),
        // Class filter
        classUI(),
        // Apply filters
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(currentFilters);
              },
              style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)))),
              child: Text(
                  "Apply ${currentFilters.isEmpty ? '' : '${currentFilters.length} '}filter(s)"),
            ),
          ),
        )
      ],
    );
  }

  Card classUI() {
    return Card(
        color: const Color.fromARGB(255, 34, 34, 34),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: ListTile(
          title: const Text("Class"),
          trailing: currentValues['classFilter'] != null
              ? Text(currentValues['classFilter'],
                  style: const TextStyle(fontSize: 15))
              : const Icon(Icons.add),
          onTap: () {
            TextEditingController classController = TextEditingController();
            if (currentValues['classFilter'] != null) {
              classController.text = currentValues['classFilter'];
            }
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Filter by a class"),
                    content: TextField(
                      controller: classController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                      ],
                      maxLength: 5,
                      autofocus: true,
                      decoration: const InputDecoration(
                          hintText: "Class abbrievation",
                          hintStyle: TextStyle(color: Colors.grey)),
                      onChanged: (value) {
                        classController.text = value.toUpperCase();
                      },
                      onSubmitted: (value) => setClass(value),
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          classController.clear();
                          setClass("");
                        },
                        child: const Text("Clear"),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => setClass(classController.text),
                        child: const Text("Set"),
                      )
                    ],
                  );
                });
          },
        ));
  }

  Card locationUI(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 34, 34, 34),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: ListTile(
        title: const Text("Locations"),
        trailing: const Icon(Icons.add),
        subtitle: currentValues['locationString'] != null
            ? Text(currentValues['locationString'],
                style:
                    const TextStyle(color: Color.fromARGB(255, 133, 133, 133)))
            : null,
        onTap: () {
          Navigator.of(context)
              .push(
                  // Use Cupertino for slide transition (I'm too lazy to make my own)
                  CupertinoPageRoute(
                      builder: (_) => FilterLocationPage(
                          currentValues['locationFilters'] ?? [])))
              .then((value) {
            if (value == null) {
              return;
            }
            setLocations(value);
          });
        },
      ),
    );
  }

  Card maxSizeUI() {
    return Card(
        color: const Color.fromARGB(255, 34, 34, 34),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, top: 12, right: 22, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Maximum lobby size",
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 17)),
                    Text(currentValues['currMaxString'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                        ))
                  ],
                ),
              ),
              Slider(
                  value: currentValues['currMaxSliderValue'],
                  max: currentValues['maximumMinValue'].toDouble(),
                  min: 1,
                  activeColor: const Color.fromARGB(255, 18, 93, 168),
                  divisions: null,
                  onChanged: (value) {
                    setMaxVal(value);
                  })
            ]));
  }

  Card minSeatsUI() {
    return Card(
        color: const Color.fromARGB(255, 34, 34, 34),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, top: 12, right: 22, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Minimum seats available",
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 17)),
                    Text(currentValues['currMinString'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                        ))
                  ],
                ),
              ),
              Slider(
                  value: currentValues['currMinSliderValue'],
                  max: currentValues['minimumMaxValue'].toDouble(),
                  activeColor: const Color.fromARGB(255, 18, 93, 168),
                  divisions: null,
                  onChanged: (value) {
                    setMinVal(value);
                  })
            ]));
  }

  Card hideFullUI() {
    return Card(
        color: const Color.fromARGB(255, 34, 34, 34),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: ListTile(
          onTap: () {
            setFull(!currentValues['hideFull']);
          },
          contentPadding: const EdgeInsets.only(left: 16, right: 8),
          title: const Text("Hide full sessions"),
          trailing: Checkbox(
              value: currentValues['hideFull'],
              activeColor: const Color.fromARGB(255, 18, 93, 168),
              onChanged: (value) {
                setFull(value);
              }),
        ));
  }

  // Function to reset UI elements and values
  void resetValues() {
    setState(() {
      currentValues.addAll(defaultValues);
    });
    currentFilters.clear();
  }

  // Round min. seats slider value to int and set string depending on value
  void setMinVal(value) {
    setState(() {
      currentValues['currMinSliderValue'] = value;
    });
    int rounded = currentValues['currMinSliderValue'].round();
    if (rounded == 0) {
      currentValues['currMinString'] = 'Any';
    } else {
      currentValues['currMinString'] =
          currentValues['currMinSliderValue'].round().toString();
    }
    setFilters('currMinSliderValue',
        currentValues['currMinSliderValue'].round().toDouble());
  }

  // Round max session room slider value to int and set string depending on value
  void setMaxVal(value) {
    setState(() {
      currentValues['currMaxSliderValue'] = value;
    });
    int rounded = currentValues['currMaxSliderValue'].round();
    if (rounded == currentValues['maximumMinValue']) {
      currentValues['currMaxString'] = 'Any';
    } else {
      currentValues['currMaxString'] =
          currentValues['currMaxSliderValue'].round().toString();
    }
    setFilters('currMaxSliderValue',
        currentValues['currMaxSliderValue'].round().toDouble());
  }

  // Set checkbox UI
  void setFull(value) {
    setState(() {
      currentValues['hideFull'] = value!;
      setFilters('hideFull', value);
    });
  }

  // Set text for subtitle of location list tile
  void setLocations(List value) {
    setState(() {
      currentValues['locationFilters'] = value;
    });

    String subtitle = value.join(", ");
    if (value.isNotEmpty) {
      if (subtitle.length > 30) {
        currentValues['locationString'] = "${subtitle.substring(0, 27)}...";
      } else {
        currentValues['locationString'] = subtitle;
      }
    } else {
      currentValues['locationString'] = null;
    }
    setFilters('locationFilters', value);
  }

  // Set class in filter if not empty
  setClass(String value) {
    String val = value.trim();
    setState(() {
      currentValues['classFilter'] = val.isEmpty ? null : val;
    });
    setFilters('classFilter', val.isEmpty ? null : val);
    Navigator.of(context).pop();
  }

  // Set values for filter, remove if default value
  void setFilters(key, value) {
    if (value != defaultValues[key]) {
      currentFilters[key] = value;
    } else {
      currentFilters.remove(key);
    }
  }
}
