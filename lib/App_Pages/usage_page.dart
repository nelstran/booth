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

class _UsagePageState extends State<UsagePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int weeksAwayFromToday = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex:1,
              child: Padding(
                padding: const EdgeInsets.only(top:16.0, left: 16, right: 16, bottom: 0),
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
            const Expanded(
              flex: 1,
              child: TabBar(
                indicatorColor: Colors.blue,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                // labelPadding: EdgeInsets.only(bottom:10),
                unselectedLabelColor: Color.fromARGB(255, 68, 68, 68),
                labelColor: Colors.white,
                tabs: [
                  Icon(Icons.access_time),
                  Icon(Icons.bar_chart_rounded)
                ]
              ),
            ),
            Expanded(
              flex: 13,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical:10),
                child: TabBarView(
                  children: [
                    weeklyBarGraph(),
                    sessionData()
                  ]
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  FutureBuilder<Map<String, dynamic>> weeklyBarGraph() {
    return FutureBuilder(
      future: getWeeklyHours(weeksAwayFromToday),
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

        if (snapshot.hasData) {
          weeklyHours = snapshot.data!;
          try{
            subjects = (weeklyHours["Subjects"] as Map).keys.toList();
            subjectsDuration = weeklyHours["Subjects"];
            subjects.sort((a, b) => subjectsDuration[b].inMinutes - subjectsDuration[a].inMinutes);
            maxSubjectTime = subjectsDuration[subjects[0]].inMinutes / 60;
          }
          catch (e){
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
        return 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex:2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          // fitInsideHorizontally: true,
                          fitInsideVertically: true,
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
                              tooltipTextTime(rod.toY),
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
                                  color: const Color.fromARGB(72, 255, 255, 255),
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
                          padding: const EdgeInsets.only(top: .0, bottom: 10.0),
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
                                      text: "Daily Average",
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
                                    totalHoursText(totalHours),
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
                            // Show only classes that have more than 0hr and 0m
                            if(duration != 0){
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
                                      backgroundColor: Colors.transparent,
                                      color: Colors.blue,
                                      ),
                                  ],
                                ),
                              );
                            }
                            else{
                              return const SizedBox.shrink();
                            }
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

  // Gets the total booth sessions joined per day
  Future<Map<String, dynamic>> getWeeklySessions(int week) async {
    String userKey = widget.controller.student.uid;

    Map<String, dynamic> weeklySessions = {
      "Sunday": 0.0,
      "Monday": 0.0,
      "Tuesday": 0.0,
      "Wednesday": 0.0,
      "Thursday": 0.0,
      "Friday": 0.0,
      "Saturday": 0.0,
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
           var dailyCount = 1;

          weeklySessions.update(json["day_of_week"],
            (value) {
              var newCount = value + dailyCount;
              (weeklySessions["Subjects"] as Map).update(json["subject"], 
                (value) => value + dailyCount,
                ifAbsent: () => 1);
              return newCount;
            });
          
        }
      },
      onError: (e) => print("Error completing: $e"),
    );

    return weeklySessions;
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
        text = const Text("Sun", style: style);
        break;
      case 1:
        text = const Text("Mon", style: style);
        break;
      case 2:
        text = const Text("Tue", style: style);
        break;
      case 3:
        text = const Text("Wed", style: style);
        break;
      case 4:
        text = const Text("Thu", style: style);
        break;
      case 5:
        text = const Text("Fri", style: style);
        break;
      case 6:
        text = const Text("Sat", style: style);
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

  Widget sessionData() {
    return FutureBuilder(
      future: Future.wait([getWeeklySessions(weeksAwayFromToday), getFreqLocation(weeksAwayFromToday)]),
      builder: (context, snapshot) {
        Map<String, dynamic> weeklySessions = {
          "Sunday": 0.0,
          "Monday": 0.0,
          "Tuesday": 0.0,
          "Wednesday": 0.0,
          "Thursday": 0.0,
          "Friday": 0.0,
          "Saturday": 0.0,
          "Subjects": {}
        };
       
        List subjects = [];
        Map subjectsCount = {};
        int maxSubjectCount = 1;

        String mostFreqLoc = "Not enough data";
        if (snapshot.hasData) {
          weeklySessions = snapshot.data![0] as Map<String, dynamic>;
          mostFreqLoc = snapshot.data![1] as String;
          try{
            subjects = (weeklySessions["Subjects"] as Map).keys.toList();
            subjectsCount = weeklySessions["Subjects"];
            subjects.sort((a, b) => subjectsCount[b] - subjectsCount[a]);
            maxSubjectCount = subjectsCount[subjects[0]];
          }
          catch (e){
            print(e);
            // No idea why subject isnt in the map
          }
        }
        // Convert Duration to double
        double sunCount= weeklySessions["Sunday"];
        double monCount = weeklySessions["Monday"];
        double tuesCount = weeklySessions["Tuesday"];
        double wedCount = weeklySessions["Wednesday"];
        double thurCount = weeklySessions["Thursday"];
        double friCount = weeklySessions["Friday"];
        double satCount = weeklySessions["Saturday"];

        // Set bar data
        BarData weeklyBarData = BarData(
            sunAmount: sunCount,
            monAmount: monCount,
            tueAmount: tuesCount,
            wedAmount: wedCount,
            thurAmount: thurCount,
            friAmount: friCount,
            satAmount: satCount);

        weeklyBarData.initializeBarData();

        // Get total weekly hours
        double totalSessions = (sunCount +
          monCount +
          tuesCount +
          wedCount +
          thurCount +
          friCount +
          satCount);

        // Get daily average
        double dailyAverageNum = totalSessions / 7;

        // If 1 digit, shows only 1 digit (ex: 2 instead of 2.0)
        String dailyAverage = dailyAverageNum.round().toString();

        // If 1 digit, shows only 1 digit (ex: 2 instead of 2.0)
        String totalString = totalSessions.round().toString();

        double maxYBar = (weeklyBarData.getMax().roundToDouble() + 1);
        return 
        Column(
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
                          fitInsideVertically: true,
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
                              tooltipText(rod.toY),
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
                          rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false
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
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxYBar + (.1 * maxYBar),
                                  color: const Color.fromARGB(72, 255, 255, 255),
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
                          padding: const EdgeInsets.only(top: .0, bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: dailyAverage,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const TextSpan(
                                      text: " Daily Average",
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
                                    checkPlural(totalString, totalSessions),
                                  ]
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                     Row(
                      children:[ 
                      const Text(
                            "Top Study Location: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold
                            )
                          ),
                          Text(mostFreqLoc),
                    ]),
                     Expanded(
                       flex: 7,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subjects.length >= 5 ? 5 : subjects.length,
                          itemBuilder: (context, index) {
                            String subject = subjects[index];
                            int subCount = subjectsCount[subject];
                            // Show only classes that have 1 session or more
                            if(subCount > 0){
                              String subCountString = "$subCount Sessions";
                              if(subCount == 1){
                                subCountString = "$subCount Session";
                              }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(subject),
                                      Text(subCountString)
                                    ],
                                  ),
                                  LinearProgressIndicator(
                                    borderRadius: BorderRadius.circular(8),
                                    minHeight: 10,
                                    value:(subCount/maxSubjectCount),
                                    backgroundColor: Colors.transparent,
                                    color: Colors.blue,
                                    ),
                                ],
                              ),
                            );
                            }
                            else {
                              return const SizedBox.shrink();
                            }
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
}

TextSpan tooltipTextTime(yval){
  int hour = yval.floor();
  int min = ((yval - hour) * 60).round();

  return  TextSpan(
            text: "$hour hr $min m",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          );
}

TextSpan totalHoursText(double totalHours){
  int hour = totalHours.floor();
  int min = ((totalHours - hour) * 60).round();

  return TextSpan(
    text: "$hour hr $min m"
  );
}

TextSpan tooltipText(yval){
  // If 1 digit, shows only 1 digit (ex: 2 instead of 2.0)
  String yvalString = yval.round().toString();
  String tooltipText = '$yvalString Sessions';
  if(yval == 1.0){
    tooltipText = "$yvalString Session";
  }
  return  TextSpan(
    text: tooltipText,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );
}

TextSpan checkPlural(totalString, totalSessions){
  String text = "$totalString Sessions";
  // Removes plural 's' if 1 session
  if(totalSessions == 1.0){
    text = "$totalString Session";
  }
  return TextSpan(
            text: text
          );
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
