import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Booth/MVC/booth_controller.dart';
import 'package:Booth/MVC/analytics_extension.dart';
import 'package:intl/intl.dart';

class UsagePage extends StatelessWidget {
  final BoothController controller;
  const UsagePage(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([getWeeklyHours(), getFreqLocation()]),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Something has happened"));
          }
          Map<String, Duration> weeklyHours = snapshot.data[0];
          String mostFreqLoc = snapshot.data[1];

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
          double totalHours = sunHours +
              monHours +
              tuesHours +
              wedHours +
              thurHours +
              friHours +
              satHours;
          String totalWeeklyHours = totalHours.toStringAsPrecision(3);

          // Get daily average
          double dailyAverageNum = totalHours / 7;
          String dailyAverage = dailyAverageNum.toStringAsPrecision(3);

          return Scaffold(
              body: Center(
                  child: SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Weekly Session Time",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                SizedBox(
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
                              throw Error();
                          }
                          return BarTooltipItem(
                            weekDay + '\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    (rod.toY).toStringAsPrecision(2) + " Hours",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      maxY: weeklyBarData.getMax() + 1,
                      minY: 0,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
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
                                    toY: weeklyBarData.getMax() + 1,
                                    color: Colors.grey[200],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Total Time this Week: " + totalWeeklyHours + "h",
                      style: TextStyle(fontSize: 20),
                    )),
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Daily Average: " + dailyAverage + "h",
                      style: TextStyle(fontSize: 20),
                    )),
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Most Visited Location this Week: " + mostFreqLoc,
                      style: TextStyle(fontSize: 20),
                    ))
              ],
            ),
          )));
        });
  }

  // Gets the most visited study location of the week
  Future<String> getFreqLocation() async {
    String userKey = "wUxLN0owVqZGEIBeMOt9q6lVBzL2";
    List<String> locations = [];
    String mostFreqLoc = "";

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection("users")
        .doc(userKey)
        .collection('session_logs')
        //.where('week_of_year', isEqualTo: getCurrentWeek())
        .where('week_of_year', isEqualTo: 39)
        .get()
        .then(
      (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          locations.add(docSnapshot.data()["location_desc"]);
        }
      },
      onError: (e) => print("Error completing: $e"),
    );

    var map = Map();

    locations.forEach((element) {
      if (map.containsKey(element)) {
        map[element] += 1;
      } else {
        map[element] = 1;
      }
    });

    List sortedCounts = map.values.toList()..sort();
    int mostFreqCount = sortedCounts.last;

    map.forEach((k, v) {
      if (v == mostFreqCount) {
        mostFreqLoc = k;
      }
    });

    return mostFreqLoc;
  }

// Gets the total hours spent in booth sessions per day
  Future<Map<String, Duration>> getWeeklyHours() async {
    String userKey = "wUxLN0owVqZGEIBeMOt9q6lVBzL2";

    Map<String, Duration> weeklyHours = {
      "Sunday": Duration(hours: 0, minutes: 0, seconds: 0),
      "Monday": Duration(hours: 0, minutes: 0, seconds: 0),
      "Tuesday": Duration(hours: 0, minutes: 0, seconds: 0),
      "Wednesday": Duration(hours: 0, minutes: 0, seconds: 0),
      "Thursday": Duration(hours: 0, minutes: 0, seconds: 0),
      "Friday": Duration(hours: 0, minutes: 0, seconds: 0),
      "Saturday": Duration(hours: 0, minutes: 0, seconds: 0)
    };

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection("users")
        .doc(userKey)
        .collection('session_logs')
        //.where('week_of_year', isEqualTo: getCurrentWeek())
        .where('week_of_year', isEqualTo: 39)
        .get()
        .then(
      (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          DateTime sessionStart = new DateFormat("yyyy-MM-dd hh:mm:ss")
              .parse(docSnapshot.data()["start_timestamp"]);
          DateTime sessionEnd = new DateFormat("yyyy-MM-dd hh:mm:ss")
              .parse(docSnapshot.data()["end_timestamp"]);
          final sessionDuration = sessionEnd.difference(sessionStart);

          weeklyHours.update(docSnapshot.data()["day_of_week"],
              (value) => value + sessionDuration);
        }
      },
      onError: (e) => print("Error completing: $e"),
    );

    return weeklyHours;
  }

  // Gets the current week
  int getCurrentWeek() {
    var timestamp = Timestamp.now().toDate();
    var todayInDays =
        timestamp.difference(DateTime(timestamp.year, 1, 1, 0, 0)).inDays;
    var week = ((todayInDays - timestamp.weekday + 10) / 7).floor();
    return week;
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

    return SideTitleWidget(child: text, axisSide: meta.axisSide);
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
