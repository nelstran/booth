import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:intl/intl.dart';

class UsagePage extends StatefulWidget {
  final BoothController controller;
  const UsagePage(
    this.controller,
    {super.key}
  );

  @override
  State<UsagePage> createState() => _UsagePageState();
}

class _UsagePageState extends State<UsagePage> {
  int weeksAwayFromToday = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex:1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: const Icon(Icons.arrow_back_ios_rounded),
                    onTap: (){
                      setState(() {
                        weeksAwayFromToday += 1;
                      });
                    }
                  ),
                  Text(
                    getStartAndEndWeek(weeksAwayFromToday),
                    style: const TextStyle(
                      fontSize: 20
                    )
                  ),
                  GestureDetector(
                    child: weeksAwayFromToday == 0 ? const SizedBox(width: 25,) : const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: (){
                      if(weeksAwayFromToday > 0){
                        setState(() {
                          weeksAwayFromToday -= 1;
                        });
                      }
                    }
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex:9,
            child: weeklyBarGraph()
          ),
        ],
      ),
    );
  }

  FutureBuilder<List<Object>> weeklyBarGraph() {
    return FutureBuilder(
      future: Future.wait([getWeeklyHours(weeksAwayFromToday), getFreqLocation(weeksAwayFromToday)]),
      builder: (context, snapshot) {
        Map<String, dynamic> weeklyHours = {
          "Sunday": const Duration(),
          "Monday": const Duration(),
          "Tuesday": const Duration(),
          "Wednesday": const Duration(),
          "Thursday": const Duration(),
          "Friday": const Duration(),
          "Saturday": const Duration(),
          "Subjects": {}
        };
        List subjects = [];
        Map subjectsDuration = {};
        double maxSubjectTime = 1;

        String mostFreqLoc = "Not enough data";
        if (snapshot.hasData) {
          weeklyHours = snapshot.data![0] as Map<String, dynamic>;
          mostFreqLoc = snapshot.data![1] as String;
          try{
            subjects = (weeklyHours["Subjects"] as Map).keys.toList();
            subjectsDuration = weeklyHours.remove("Subjects");
            subjects.sort((a, b) => subjectsDuration[b].inMinutes - subjectsDuration[a].inMinutes);
            maxSubjectTime = subjectsDuration[subjects[0]].inMinutes / 60;
          }
          catch (e){
            print(e);
            // No idea why subject isnt in the map
          }
        }

        // Convert Duration to double
        double sunHours = weeklyHours["Sunday"]!.inMinutes / 60;
        double monHours = weeklyHours["Monday"]!.inMinutes / 60;
        double tuesHours = weeklyHours["Tuesday"]!.inMinutes / 60;
        double wedHours = weeklyHours["Wednesday"]!.inMinutes / 60;
        double thurHours = weeklyHours["Thursday"]!.inMinutes / 60;
        double friHours = weeklyHours["Friday"]!.inMinutes / 60;
        double satHours = weeklyHours["Saturday"]!.inMinutes / 60;

        // Set bar data
        BarData weeklyBarData = BarData(
            sunAmount: sunHours,
            monAmount: monHours,
            tueAmount: tuesHours,
            wedAmount: wedHours,
            thurAmount: thurHours,
            friAmount: friHours,
            satAmount: satHours);

        weeklyBarData.initializeBarData();

        // Get total weekly hours
        double totalHours = (sunHours +
          monHours +
          tuesHours +
          wedHours +
          thurHours +
          friHours +
          satHours);

        // Get daily average
        double dailyAverageNum = totalHours / 7;
        int averageHour = dailyAverageNum.floor();
        int averageMin = ((dailyAverageNum - averageHour) * 60).round();
        // String dailyAverage = dailyAverageNum.toStringAsPrecision(3);
        double maxYBar = (weeklyBarData.getMax().roundToDouble() + 1);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex:2,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String weekDay;
                          switch (group.x.toInt()) {
                            case 0:
                              weekDay = 'Sunday';
                              break;
                            case 1:
                              weekDay = 'Monday';
                              break;
                            case 2:
                              weekDay = 'Tuesday';
                              break;
                            case 3:
                              weekDay = 'Wednesday';
                              break;
                            case 4:
                              weekDay = 'Thursday';
                              break;
                            case 5:
                              weekDay = 'Friday';
                              break;
                            case 6:
                              weekDay = 'Saturday';
                              break;
                            default:
                              weekDay = 'Invalid day';
                          }
                          return BarTooltipItem(
                            '$weekDay \n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '${(rod.toY).toStringAsPrecision(2)} Hours',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      maxY: maxYBar + (.1 * maxYBar),
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false
                            )
                          ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false
                            )
                          ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            maxIncluded: false,
                            minIncluded: false,
                            getTitlesWidget: (amount, meta) => SideTitleWidget(
                              axisSide: AxisSide.right,
                              child: Text("${amount.toStringAsFixed(1).replaceFirst(RegExp(r'\.?0*$'), '')} hr"), 
                              ),
                            interval: (maxYBar / 2),
                            reservedSize: 50,
                            showTitles: true
                            )
                          ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getBottomTitles,
                          ),
                        ),
                      ),
                      barGroups: weeklyBarData.barData
                        .map(
                          (data) => BarChartGroupData(
                            x: data.x,
                            barRods: [
                              BarChartRodData(
                                toY: data.y,
                                color: Colors.blue,
                                width: 25,
                                // borderRadius: BorderRadius.circular(15),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxYBar + (.1 * maxYBar),
                                  color: Colors.grey[200],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList()
                      )
                    ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 43, 43, 43),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40.0),
                    topRight: Radius.circular(40.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: .0, bottom: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:"$averageHour hr $averageMin m\n",
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const TextSpan(
                                      text: "Daily Average study time",
                                      style: TextStyle(
                                        fontSize: 15,
                                      )
                                    )
                                  ]
                                ),
                              ),
                              RichText(
                                textAlign: TextAlign.end,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Total:\n",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      )
                                    ),
                                    TextSpan(
                                      text: "${totalHours.toStringAsFixed(2)} hr"
                                    )
                                  ]
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subjects.length >= 5 ? 5 : subjects.length,
                          itemBuilder: (context, index) {
                            String subject = subjects[index];
                            double duration = subjectsDuration[subject]!.inMinutes / 60;
                            int hours = duration.floor();
                            int minutes = (((duration - hours) * 60).round());
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(subject),
                                      Text("$hours hr $minutes m")
                                    ],
                                  ),
                                  LinearProgressIndicator(
                                    borderRadius: BorderRadius.circular(8),
                                    minHeight: 10,
                                    value:(duration / maxSubjectTime),
                                    color: Colors.blue)
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  // Gets the most visited study location of the week
  Future<String> getFreqLocation(int week) async {
    // String userKey = "wUxLN0owVqZGEIBeMOt9q6lVBzL2";
    String userKey = widget.controller.student.uid;

    List<String> locations = [];
    String mostFreqLoc = "";
    try{
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore
          .collection("users")
          .doc(userKey)
          .collection('session_logs')
          .where('week_of_year', isEqualTo: getWeekNum(week))
          // .where('week_of_year', isEqualTo: 39)
          .get()
          .then(
        (querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            locations.add(docSnapshot.data()["location_desc"]);
          }
        },
        onError: (e) => print("Error completing: $e"),
      );

      var map = {};

      for(var element in locations){
        if (map.containsKey(element)) {
          map[element] += 1;
        } else {
          map[element] = 1;
        }
      }
      
      List sortedCounts = map.values.toList()..sort();
      int mostFreqCount = sortedCounts.last;

      map.forEach((k, v) {
        if (v == mostFreqCount) {
          mostFreqLoc = k;
        }
      });

      return mostFreqLoc;
    }
    catch (e) {
      return "";
    }
  }

// Gets the total hours spent in booth sessions per day
  Future<Map<String, dynamic>> getWeeklyHours(int week) async {
    // String userKey = "wUxLN0owVqZGEIBeMOt9q6lVBzL2";
    String userKey = widget.controller.student.uid;

    Map<String, dynamic> weeklyHours = {
      "Sunday": const Duration(),
      "Monday": const Duration(),
      "Tuesday": const Duration(),
      "Wednesday": const Duration(),
      "Thursday": const Duration(),
      "Friday": const Duration(),
      "Saturday": const Duration(),
      "Subjects": {}
    };

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection("users")
        .doc(userKey)
        .collection('session_logs')
        .where('week_of_year', isEqualTo: getWeekNum(week))
        .get()
        .then(
      (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          if (docSnapshot.id == "curr_session"){
            continue;
          }
          Map json = docSnapshot.data() as Map;
          DateTime sessionStart = DateFormat("yyyy-MM-dd hh:mm:ss")
              .parse(json["start_timestamp"]);
          DateTime sessionEnd = DateFormat("yyyy-MM-dd hh:mm:ss")
              .parse(json["end_timestamp"]);
          final sessionDuration = sessionEnd.difference(sessionStart);

          weeklyHours.update(json["day_of_week"],
            (value) {
              Duration newDur = value + sessionDuration;
              (weeklyHours["Subjects"] as Map).update(json["subject"], 
                (value) => value + sessionDuration,
                ifAbsent: () => newDur);
              return newDur;
            });
          
        }
      },
      onError: (e) => print("Error completing: $e"),
    );

    return weeklyHours;
  }

  // Gets the current week
  int getWeekNum(int week) {
    var timestamp = Timestamp.now().toDate();
    timestamp = timestamp.subtract(Duration(days: 7 * week));
    var todayInDays =
        timestamp.difference(DateTime(timestamp.year, 1, 1, 0, 0)).inDays;
    var weekNum = ((todayInDays - timestamp.weekday + 10) / 7).floor();
    return weekNum;
  }

  String getStartAndEndWeek(int week){
    var date = Timestamp.now().toDate();
    date = date.subtract(Duration(days: week * 7));
    var startMonth = DateFormat.MMMM().format(date);
    var startWeekDay = date.subtract(Duration(days: date.weekday));
    var startNum = int.parse(DateFormat.d().format(startWeekDay));
    var endMonth = DateFormat.MMMM().format(date.add(Duration(days: 7 - date.weekday)));
    var endWeekDay = date.add(Duration(days: 6 - date.weekday));
    var endNum = int.parse(DateFormat.d().format(endWeekDay));
    return "$startMonth $startNum  -  $endMonth $endNum";
  }

  // Gets the bottom axis of the chart
  Widget getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text("S", style: style);
        break;
      case 1:
        text = const Text("M", style: style);
        break;
      case 2:
        text = const Text("T", style: style);
        break;
      case 3:
        text = const Text("W", style: style);
        break;
      case 4:
        text = const Text("T", style: style);
        break;
      case 5:
        text = const Text("F", style: style);
        break;
      case 6:
        text = const Text("S", style: style);
        break;
      default:
        text = const Text("", style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text, 
    );
  }
}

class BarData {
  final double sunAmount;
  final double monAmount;
  final double tueAmount;
  final double wedAmount;
  final double thurAmount;
  final double friAmount;
  final double satAmount;

  BarData({
    required this.sunAmount,
    required this.monAmount,
    required this.tueAmount,
    required this.wedAmount,
    required this.thurAmount,
    required this.friAmount,
    required this.satAmount,
  });

  List<IndivididualBar> barData = [];

  double getMax() {
    return ([
      sunAmount,
      monAmount,
      tueAmount,
      wedAmount,
      thurAmount,
      friAmount,
      satAmount
    ]).reduce(max);
  }

  void initializeBarData() {
    barData = [
      IndivididualBar(x: 0, y: sunAmount),
      IndivididualBar(x: 1, y: monAmount),
      IndivididualBar(x: 2, y: tueAmount),
      IndivididualBar(x: 3, y: wedAmount),
      IndivididualBar(x: 4, y: thurAmount),
      IndivididualBar(x: 5, y: friAmount),
      IndivididualBar(x: 6, y: satAmount)
    ];
  }
}

class IndivididualBar {
  final int x;
  final double y;

  IndivididualBar({
    required this.x,
    required this.y,
  });
}
