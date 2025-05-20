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

  Stream<AccelerometerEvent> accelerometerEventStream({
    Duration samplingPeriod = const Duration(milliseconds:50),
  }) {
    return sensors.accelerometerEventStream(samplingPeriod: samplingPeriod);
  }

  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    return sensors.gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }

  late StreamSubscription<GyroscopeEvent> _gyroSub;
  late StreamSubscription<AccelerometerEvent> _accelSub;

  //late Timer _sendTimer;

  final String serverIP = 'http://localhost:5000/data';

  double ax = 0.0, ay = 0.0, az = 0.0, gx = 0.0, gy = 0.0, gz = 0.0;
  final dt = 0.02;
  vm.Vector3 velocity = vm.Vector3.zero();
  vm.Vector3 position = vm.Vector3.zero();
  vm.Vector3 orientation = vm.Vector3.zero(); // roll, pitch, yaw
  final List<Offset> _path = [Offset(200, 400)];
  vm.Vector3 lastAccel = vm.Vector3.zero();
  final double scaleFactor = 60.0;
  vm.Vector3 gravity = vm.Vector3.zero();


  @override
  void initState() {
    super.initState();

    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event){
      ax = event.x;
      ay = event.y;
      az = event.z;
      handleAccelerometer(event);
    });

    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event){
      gx = event.x;
      gy = event.y;
      gz = event.z;
      orientation += vm.Vector3(event.x, event.y, event.z) * dt;
      final Offset point = Offset(event.x, event.y) * scaleFactor;
      setState(() {
        
      _path.add(point);

      if (_path.length > bufferSize) {
        _path.removeAt(0);
      }

      if (detectCircle(_path)) {
        print("Circle detected!");

      }
     
    });
    });
  }


  final int bufferSize = 10;

  void handleAccelerometer(AccelerometerEvent event) {
    final raw = vm.Vector3(event.x, event.y, event.z);

    // Estimate gravity
    gravity = gravity * 0.8 + raw * 0.2;

    // Subtract gravity
    final linear = raw - gravity;

    // Take only horizontal motion
    final Offset point = Offset(linear.x, linear.y) * scaleFactor;
    /**
    setState(() {
      _path.add(point);

      if (_path.length > bufferSize) {
        _path.removeAt(0);
      }

      if (detectCircle(_path)) {
        print("Circle detected!");

      }
    }); */
  }

  Offset computeCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    final sum = points.reduce((a, b) => a + b);
    return sum / points.length.toDouble();
  }

  double standardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
  }

  bool detectCircle(List<Offset> points) {
    //print("CI SONO");
    if (points.length < 10) return false;

    final center = computeCentroid(points);
    final angles = <double>[];
    final radii = <double>[];

    for (var p in points) {
      final rel = p - center;
      angles.add(atan2(rel.dy, rel.dx));
      radii.add(rel.distance);
    }

    angles.sort();
    final angleSpan = angles.last - angles.first;
    final radiusStdev = standardDeviation(radii);
    final xStdev = standardDeviation(points.map((p) => p.dx).toList());
    final yStdev = standardDeviation(points.map((p) => p.dy).toList());
    //print(xStdev.toString()+","+yStdev.toString());
    final radiusMean = radii.reduce((a, b) => a + b) / radii.length;

    final isClosed = (points.first - points.last).distance < radiusMean * 0.9;
    //print((points.first - points.last).distance.toString()+","+radiusMean.toString());
    final hasFullRotation = angleSpan > 5.5; // we don't use it right now
    
    final isCircleLike = xStdev>80 || yStdev>80;
    //print(isCircleLike.toString());

    return isCircleLike;
  }

    @override
    void dispose() {
      _accelSub.cancel();
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
            CustomPaint(
              painter: CirclePathPainter(_path),
              child: Container(),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Accelerometer: $ax, $ay, $az"),
                  SizedBox(height: 8),
                  Text("Gyroscope: $gx, $gy, $gz"),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Indietro"),
                  )
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