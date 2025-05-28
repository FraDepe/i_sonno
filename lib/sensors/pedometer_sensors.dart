import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;

class PedometerSensorApp extends StatefulWidget {
  const PedometerSensorApp({super.key});

  @override
  _PedometerSensorAppState createState() => _PedometerSensorAppState();
}

class _PedometerSensorAppState extends State<PedometerSensorApp> {

  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
    }) {
    //fixme Perchè usiamo due import uguali ma uno ha un nome?
    //E soprattutto perchè se usiamo solamente l'import senza nome l'app va in Stack Overflow?
    return sensors.gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }
  Stream<AccelerometerEvent> accelerometerEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
    }) {
    //fixme Perchè usiamo due import uguali ma uno ha un nome?
    //E soprattutto perchè se usiamo solamente l'import senza nome l'app va in Stack Overflow?
    return sensors.accelerometerEventStream(samplingPeriod: samplingPeriod);
  }
  Stream<MagnetometerEvent> magnetometerEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
    }) {
    //fixme Perchè usiamo due import uguali ma uno ha un nome?
    //E soprattutto perchè se usiamo solamente l'import senza nome l'app va in Stack Overflow?
    return sensors.magnetometerEventStream(samplingPeriod: samplingPeriod);
  }

  late StreamSubscription<AccelerometerEvent> _accelSub;
  late StreamSubscription<GyroscopeEvent> _gyroSub;
  late StreamSubscription<MagnetometerEvent> _magnetoSub;
  static double _progress = 0.0;
  String task_completed = "";
  // Booleans to track movement
  bool accelTriggered = false;
  bool gyroTriggered = false;
  bool magTriggered = false;

  int stepCount = 0;
  int lastStepTime = 0;

  // Thresholds
  final double accelThreshold = 20.5;
  final double gyroThreshold = 20.2;
  final double magThreshold = 10.0;
  final int stepCooldown = 500; // ms

  // Previous values
  double prevAccelZ = 0.0;
  double prevGyroMagnitude = 0.0;
  double prevMagMagnitude = 0.0;

  @override
  void initState() {
    super.initState();

    _accelSub = accelerometerEventStream().listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (prevAccelZ < accelThreshold && event.z >= accelThreshold) {
        accelTriggered = true;
        _checkAndCountStep(now);
      }
      prevAccelZ = event.z;
    });

    _gyroSub = gyroscopeEventStream().listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      double mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (prevGyroMagnitude < gyroThreshold && mag >= gyroThreshold) {
        gyroTriggered = true;
        _checkAndCountStep(now);
      }
      prevGyroMagnitude = mag;
    });

    _magnetoSub = magnetometerEventStream().listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      double mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if ((mag - prevMagMagnitude).abs() > magThreshold) {
        magTriggered = true;
        _checkAndCountStep(now);
      }
      prevMagMagnitude = mag;
    });
  }

  void _checkAndCountStep(int now) {
    print(accelTriggered.toString()+","+gyroTriggered.toString()+","+magTriggered.toString());
    if (accelTriggered && gyroTriggered && magTriggered &&
        now - lastStepTime > stepCooldown) {
      setState(() {
        _progress+=1/100;
      });
      lastStepTime = now;

      // Reset triggers after successful step
      accelTriggered = gyroTriggered = magTriggered = false;
    }
  }  

  @override
  void dispose() {
    _accelSub.cancel();
    _gyroSub.cancel();
    _magnetoSub.cancel();
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
                  Center(
                    // Forse non è tanto uno shake ma più una rotazione (ruota il telefono...)
                    child: Text("Cammina fino a completamento della barra")
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
                        Center(child: Text(task_completed)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.popUntil(context, (route) => route.settings.name == "/"),
          child: Icon(Icons.backspace),
        ),
      ),
    );
  }


  }

  


