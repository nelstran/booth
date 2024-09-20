import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  // @override
  // Widget build(BuildContext context) {
  //    return Column(
  //      children: [
  //        Expanded(
  //         child: Image.asset(
  //                   'assets/images/usage.png'),
  //            ),
  //      ],
  //    );
  //   // return const Text("Usage Placeholder");
  // }

  
  @override
  Widget build(BuildContext context) {

   List<double> weeklySummary = [4, 5, 7, 2, 1, 8, 3];

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
              barGroups: myBarData.barData.map((data) => BarChartGroupData(
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


