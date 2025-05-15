import 'dart:async';
import 'dart:convert';
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
  late Timer _sendTimer;

  final String serverIP = 'http://localhost:5000/data';

  double ax = 0.0, ay = 0.0, az = 0.0, gx = 0.0, gy = 0.0, gz = 0.0;

  @override
  void initState() {
    super.initState();

    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event){
      ax = event.x;
      ay = event.y;
      az = event.z;
    });

    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event){
      gx = event.x;
      gy = event.y;
      gz = event.z;
    });
    _sendTimer = Timer.periodic(Duration(seconds: 1), (_) => sendData());
  }
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

    @override
    void dispose() {
      _accelSub.cancel();
      _gyroSub.cancel();
      _sendTimer.cancel();
      super.dispose();
    }

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Sensor Data')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Values are"+ax.toString()+","+ay.toString()+","+az.toString()),
              SizedBox(height: 16),
              Text("Values are"+gx.toString()+","+gy.toString()+","+gz.toString()),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}