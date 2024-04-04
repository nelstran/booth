// import 'dart:ui';
import 'dart:math';

class Session{
  final String field;
  final int level;
  final String topic;
  int dist;
  int currNum;
  int maxNum;
  // Color color;


  Session({
    required this.field,
    required this.level,
    required this.topic,
    int? dist,
    int? currNum,
    int? maxNum,
    }) 
    : 
    // dist = dist ?? 0,
    dist = dist ?? 10 + Random().nextInt(100 - 10 + 1),
    currNum = currNum ?? 1,
    maxNum = maxNum ?? 0;
    // color = colorLibrary.addField(field); // Group sessions by the Field they're in
}