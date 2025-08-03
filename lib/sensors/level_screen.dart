import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({required this.alarmId, super.key});

  final int alarmId;

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  StreamSubscription? _accSub;
  
  final Queue<double> _yValues = Queue<double>();
  static const int _smoothingWindow = 10;
  double yPosition = 0;

  double targetY = 0;

  //int x = 0;
  //int y = 0;
  //double xDotPosition = 0;
  //double yDotPosition = 0;
  bool isCorrectLevel = false;
  List<ColorSwatch<int>> badColors = [
    Colors.red,
    Colors.redAccent,
  ];
  List<ColorSwatch<int>> correctColors = [  //TODO giallo?
    Colors.green,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();

    generateRandomTargetTilt();

    _accSub = accelerometerEventStream().listen((event) {
      final normalizedY = scaleY(event.y);
      _addSmoothedValue(normalizedY);
      setState(() {
        //x = calculateXValue(event);
        yPosition = _average(_yValues);
        //y = calculateYValue(event);
        //xDotPosition = getXDotPosition(event.x);
        //yDotPosition = getYDotPosition(event.y);
        //isCorrectLevel = isCorrectLevel = isWithinTolerance(_average(_yValues) * 9.8, 0.35) /*&& isWithinTolerance(event.x, 0.35)*/;
        isCorrectLevel = (_average(_yValues) - targetY).abs() < 0.015;
        debugPrint((event.y * 10).round().toString());
      });
    });
  }

  void _addSmoothedValue(double value) {
    _yValues.add(value);
    if (_yValues.length > _smoothingWindow) {
      _yValues.removeFirst();
    }
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double scaleY(double rawY) {
    return (rawY / 9.8).clamp(-1.0, 1.0);
  }

  double getXDotPosition(double xValue) {
    if (isCorrectLevel) {
      return 0;
    } else {
      return xValue;
    }
  }
  double getYDotPosition(double yValue) {
    if (isCorrectLevel) {
      return 0;
    } else {
      return yValue;
    }
  }

  //int calculateYValue(AccelerometerEvent event) {
  //  return (event.y * 10).round();
  //}

  //int calculateXValue(AccelerometerEvent event) {
  //  return (event.x * 10 - 2).round();
  //}

  bool isWithinTolerance(double value, double tolerance) {
   return value.abs() < tolerance;
  }

  void generateRandomTargetTilt() {
    final random = Random();
   targetY = (random.nextDouble() * 1.6) - 0.8; // -0.8 to +0.8
  }

  List<ColorSwatch<int>> getBackgroundColor() {
    return isCorrectLevel ? correctColors : badColors;
  }

  @override
  void dispose() {
    debugPrint('------------------------- Dispose ---------------------------');
    _accSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Screen'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1,
                colors: getBackgroundColor(),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              'Target tilt: ${atan(targetY * 9.8) * (180 / pi)} °',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Divider(
              color: Colors.white,
              thickness: 10,
              indent: 50,
              endIndent: 50,
            ),
          ),
          // Barra mobile verticale
          AnimatedAlign(
            duration: const Duration(milliseconds: 100),
            alignment: Alignment(0, yPosition),
            child: Container(
              width: 180,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          /*Center(
            child: ClipOval(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child:AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              alignment: Alignment(xDotPosition/10, yDotPosition/10),
              child: ClipOval(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Center(
            child:AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              alignment: Alignment(-xDotPosition/10, -yDotPosition/10),
              child: ClipOval(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.white,
                ),
              ),
            ),
          ), */
        ],
      ),
    );
  }
}
