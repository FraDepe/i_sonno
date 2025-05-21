import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart' as sensors;



class SensorApp extends StatefulWidget {
  @override
  _SensorAppState createState() => _SensorAppState();
}
class _SensorAppState extends State<SensorApp> {

  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    return sensors.gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }

  late StreamSubscription<GyroscopeEvent> _gyroSub;

  final List<Offset> _path = [Offset(200, 400)];
  final double scaleFactor = 60.0;

  static double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _progress=0.0;
    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event){

      final Offset point = Offset(event.x, event.y) * scaleFactor;
      setState(() {
        
      _path.add(point);

      if (_path.length > bufferSize) {
        _path.removeAt(0);
      }

      if (detectShake(_path)) {
        print("Shake detected!");
        _progress += 1/200;
        if(_progress >= 1){_progress=0.0;}

      }
     
    });
    });
  }


  final int bufferSize = 10;

  
 
  double standardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
  }

  bool detectShake(List<Offset> points) {
    //print("CI SONO");
    if (points.length < 10) return false;

  
    final xStdev = standardDeviation(points.map((p) => p.dx).toList());
    final yStdev = standardDeviation(points.map((p) => p.dy).toList());
   
    final isShaking = xStdev>80 || yStdev>80;


    return isShaking;
  }

    @override
    void dispose() {
      _gyroSub.cancel();
      //_sendTimer.cancel();
      super.dispose();
    }

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Sensor Data')),
        body: Stack(
          children: [
          
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Indietro"),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 20,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),SizedBox(height: 20),
                  Text('${(_progress * 100).toStringAsFixed(0)}% completato'),
                  SizedBox(height: 40),
                ],
              ),
          ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() => _path.clear()),
          child: Icon(Icons.clear),
        ),
      ),
    );
  }
}

class CirclePathPainter extends CustomPainter {
  final List<Offset> points;

  CirclePathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 1; i < points.length; i++) {
      final p1 = center + points[i - 1];
      final p2 = center + points[i];
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

