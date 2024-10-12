import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/MVC/booth_controller.dart';
import 'package:flutter_application_1/MVC/analytics_extension.dart';
import 'package:intl/intl.dart';

class UsagePage extends StatelessWidget {
  final BoothController controller;
  const UsagePage(this.controller, {super.key});

  
  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: getWeeklyHours(), 
      builder: (context, snapshot){
        if (snapshot.connectionState == ConnectionState.waiting)
        {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData){
          return const Center(child: Text("Something has happened"));
        }
        Map<String, Duration> weeklyHours = snapshot.data!;
    // Hours are all 0
    print("calling get weekly hours");
    print(weeklyHours.toString());

    // Convert Duration to int
    int sunHours = weeklyHours["Sunday"]!.inHours;
    int monHours = weeklyHours["Monday"]!.inHours;
    int tuesHours = weeklyHours["Tuesday"]!.inHours;
    int wedHours = weeklyHours["Wednesday"]!.inHours;
    int thurHours = weeklyHours["Thursday"]!.inHours;
    int friHours = weeklyHours["Friday"]!.inHours;
    int satHours = weeklyHours["Saturday"]!.inHours;
  
    // Convert int to double for plotting 
    BarData weeklyBarData = BarData(
                      sunAmount: sunHours.toDouble(),
                      monAmount: monHours.toDouble(),
                      tueAmount: tuesHours.toDouble(),
                      wedAmount: wedHours.toDouble(),
                      thurAmount: thurHours.toDouble(),
                      friAmount: friHours.toDouble(),
                      satAmount: satHours.toDouble()
                    );

    weeklyBarData.initializeBarData();
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: 24,
              minY: 0,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, 
                  getTitlesWidget: getBottomTitles,
                ),
                ),
              ),
              barGroups: weeklyBarData.barData.map((data) => BarChartGroupData(
                x: data.x,
                barRods: [
                  BarChartRodData(
                    toY: data.y, 
                    color: Colors.blue,
                    width:25,
                    //borderRadius: BorderRadiues.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 24,
                      color: Colors.grey[200],
                    ),
                  ),
                ],
              ),).toList(),
            ),
          ),
        ),
      ),
    );
      });
  }

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
    await firestore.collection("users")
              .doc(userKey)
              .collection('session_logs')
              //.where('week_of_year', isEqualTo: getCurrentWeek())
              .where('week_of_year', isEqualTo: 39)
              .get()
              .then(
                (querySnapshot) {
                  for (var docSnapshot in querySnapshot.docs) {
                    DateTime sessionStart = new DateFormat("yyyy-MM-dd hh:mm:ss").parse(docSnapshot.data()["start_timestamp"]);
                    DateTime sessionEnd = new DateFormat("yyyy-MM-dd hh:mm:ss").parse(docSnapshot.data()["end_timestamp"]);
                    final sessionDuration = sessionEnd.difference(sessionStart);
                    
                    weeklyHours.update(docSnapshot.data()["day_of_week"], (value) => value + sessionDuration);
                  }
                  // Hours are correctly populated
                  print("right after populating");
                  print(weeklyHours.toString());
                },
                onError: (e) => print("Error completing: $e"),
              );
   // Hours are all 0
   print("before return");
   print(weeklyHours.toString());
   return weeklyHours;
 }

  int getCurrentWeek(){
    var timestamp = Timestamp.now().toDate();
    var todayInDays = timestamp.difference(DateTime(timestamp.year, 1, 1, 0, 0)).inDays;
    var week = ((todayInDays - timestamp.weekday + 10)/7).floor();
    return week;
  }

  Widget getBottomTitles (double value, TitleMeta meta){
    
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    Widget text;
    switch (value.toInt()){
      case 0:
        text = const Text("Sun", style: style);
        break;
      case 1:
        text = const Text("Mon", style: style);
        break;
      case 2:
        text = const Text("Tues", style: style);
        break;
      case 3:
        text = const Text("Wed", style: style);
        break;
      case 4:
        text = const Text("Thurs", style: style);
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

    return SideTitleWidget(child: text, axisSide: meta.axisSide);

  }

}


class BarData{
  
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


