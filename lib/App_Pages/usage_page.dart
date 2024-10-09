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
   List<double> weeklySummary = [4, 5, 7, 2, 1, 8, 3];
   String userKey;
   userKey = "wUxLN0owVqZGEIBeMOt9q6lVBzL2";

   BarData myBarData = BarData(
    sunAmount: weeklySummary[0],
    monAmount: weeklySummary[1],
    tueAmount: weeklySummary[2],
    wedAmount: weeklySummary[3],
    thurAmount: weeklySummary[4],
    friAmount: weeklySummary[5],
    satAmount: weeklySummary[6]
   );

   myBarData.initializeBarData();


    return Scaffold(
       body: FutureBuilder<Map<dynamic, dynamic>>(
        future: controller.fetchUserStudyData(userKey), 
        
        builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found.'));
          }
          final studyData = snapshot.data!;

          //////////////////////////////////////////////////////////////// NEW CODE FOR QUERYING DATA 

          final startRange = getStartOfWeek(DateTime.now());
          final endRange = getEndOfWeek(DateTime.now());
          
          FirebaseFirestore firestore = FirebaseFirestore.instance;
          
          firestore.collection('session_logs')
                    // instead of startRange and endRange, pass in dates to what we actually have 
                    // i tried "2024-21-09" as start and "2024-26-09" as end
                    .where('start_timestamp', isEqualTo: startRange)
                    .where('end_timestamp', isEqualTo: endRange)
                    .get()
                    .then(
                      (querySnapshot) {
                        print("success");
                        for (var docSnapshot in querySnapshot.docs) {
                          // This should print the data the query retrieves
                          print('${docSnapshot.id} => ${docSnapshot.data()}');
                        }
                      },
                      onError: (e) => print("Error completing: $e"),
                    );

          //////////////////////////////////////////////////////////////////////////////////////////////
         
          return ListView.builder(
              itemCount:  studyData.length,
              itemBuilder: (context, index) {
                
                final studySessionID = studyData.keys.elementAt(index);
                final studyMap = studyData[studySessionID];

                DateTime sessionStart = new DateFormat("yyyy-MM-dd hh:mm:ss").parse(studyMap["start_timestamp"]);
                DateTime sessionEnd = new DateFormat("yyyy-MM-dd hh:mm:ss").parse(studyMap["end_timestamp"]);
                final sessionDuration = sessionEnd.difference(sessionStart);

                return ListTile(
                  title: Text("start:" + studyMap["start_timestamp"].toString() + " end:" + studyMap["end_timestamp"].toString() + "  duration:" + sessionDuration.toString())
                  );
              }
          );
        }
       )
    );

  

    // return Scaffold(
    //   body: Center(
    //     child: SizedBox(
    //       height: 200,
    //       child: BarChart(
    //         BarChartData(
    //           maxY: 24,
    //           minY: 0,
    //           gridData: FlGridData(show: false),
    //           borderData: FlBorderData(show: false),
    //           titlesData: FlTitlesData(
    //             show: true,
    //             topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    //             leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    //             rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    //             bottomTitles: AxisTitles(sideTitles: SideTitles(
    //               showTitles: true, 
    //               getTitlesWidget: getBottomTitles,
    //             ),
    //             ),
    //           ),
    //           barGroups: myBarData.barData.map((data) => BarChartGroupData(
    //             x: data.x,
    //             barRods: [
    //               BarChartRodData(
    //                 toY: data.y, 
    //                 color: Colors.blue,
    //                 width:25,
    //                 //borderRadius: BorderRadiues.circular(4),
    //                 backDrawRodData: BackgroundBarChartRodData(
    //                   show: true,
    //                   toY: 24,
    //                   color: Colors.grey[200],
    //                 ),
    //               ),
    //             ],
    //           ),).toList(),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  DateTime getStartOfWeek(DateTime date) {
    int weekDay = date.weekday;
    return date.subtract(Duration(days: weekDay - 1));
  }

  DateTime getEndOfWeek(DateTime date) {
    int weekDay = date.weekday;
    return date.add(Duration(days: 7 - weekDay));
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


