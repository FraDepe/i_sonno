import 'dart:convert';
import 'dart:async';
import 'dart:math';
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
    Duration samplingPeriod = SensorInterval.normalInterval,
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

  final List<Offset> _path = [Offset(200, 400)];//centers the movement
  //late Timer _sendTimer;

  final String serverIP = 'http://localhost:5000/data';

  double ax = 0.0, ay = 0.0, az = 0.0, gx = 0.0, gy = 0.0, gz = 0.0;
  double yaw = 0.0, dt = 0.0;
  double lastTimestamp = 0.0;
  double velocityX = 0.0, velocityY = 0.0;
  double posX = 0.0, posY = 0.0;
  //valori presi con chatgpt, bisogna capirli bene
  double scale = 50.0; // Try 50–100 for visibility
  double startX = 200.0;
  double startY = 400.0;

  @override
  void initState() {
    super.initState();

    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event){
      setState(() {
        ax = event.x;
        ay = event.y;
        az = event.z;
        final x = event.x;
        final y = event.y;

        // Remove gravity? You could apply a high-pass filter or just ignore Z.

        // Rotate acceleration using yaw
        final worldX = x * cos(yaw) - y * sin(yaw);
        final worldY = x * sin(yaw) + y * cos(yaw);

        // Integrate into position (pseudo)
        velocityX += worldX * dt;
        velocityY += worldY * dt;

        posX += velocityX * dt;
        posY += velocityY * dt;

        // Draw this position
        _path.add(Offset(startX + posX * scale, startY + posY * scale));

        });
      });

    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event){
      setState(() {
        gx = event.x;
        gy = event.y;
        gz = event.z;

        final now = DateTime.now().millisecondsSinceEpoch.toDouble();
        dt = (lastTimestamp == 0.0) ? 0.0 : (now - lastTimestamp) / 1000.0;
        lastTimestamp = now;

        // Integrate gyroscope.z to get yaw (rotation around Z)
        yaw += event.z * dt;
      });
    });
    //_sendTimer = Timer.periodic(Duration(seconds: 1), (_) => sendData());
  }
  /**
  void sendData() async {
    try {
      final response = await http.post(
        Uri.parse(serverIP),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accelerometer': {'x': ax, 'y': ay, 'z': az},
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode != 200) {
        print('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending data: $e');
    }
  }
*/
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
              size: Size.infinite,
              painter: PathPainter(_path),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Accelerometer: $ax, $ay, $az"),
                  SizedBox(height: 8),
                  Text("Gyroscope: $gx, $gy, $gz"),
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

class PathPainter extends CustomPainter {
  final List<Offset> path;
  PathPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (path.length > 1) {
      final pathObj = Path()..moveTo(path[0].dx, path[0].dy);
      for (final point in path.skip(1)) {
        pathObj.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(pathObj, paint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}