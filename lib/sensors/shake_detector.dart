import 'dart:async';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:i_Sonno_Beta/sensors/pedometer_detector.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;
import 'package:sensors_plus/sensors_plus.dart';

class Offset3D {

  const Offset3D(this.dx, this.dy, this.dz);
  final double dx;
  final double dy;
  final double dz;

  Offset3D operator *(double scale) => Offset3D(dx * scale, dy * scale, dz * scale);

  @override
  String toString() => 'Offset3D(x: $dx, y: $dy, z: $dz)';
}

class SensorApp extends StatefulWidget {
  const SensorApp({required this.alarmId, super.key});

  final int alarmId;

  @override
  _SensorAppState createState() => _SensorAppState();
}

class _SensorAppState extends State<SensorApp> {

  final int bufferSize = 10;

  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    return sensors.gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }

  late StreamSubscription<GyroscopeEvent> _gyroSub;

  final List<Offset3D> _path = [const Offset3D(200, 400, 0)];
  final double scaleFactor = 60;
  String task_completed = '';
  int _axis = 0;
  String _axis_text = '';
  bool isNavigating = false;

  static final ValueNotifier<double> _progress = ValueNotifier(0);

  @override
  void initState() {
    super.initState();

    _axis = Random().nextInt(3);
    _axis_text = (_axis==0)?'x':(_axis==1)?'y':'z';
    _progress.value = 0.0;
    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) async {

      final point = Offset3D(event.x, event.y, event.z) * scaleFactor;

      setState(() {
        _path.add(point);
        if (_path.length > bufferSize) {
          _path.removeAt(0);
        }
      });

      if (_progress.value < 1 && detectStandingStill(_path)) {
        if (_progress.value > 1/300) {
          setState(() {
            _progress.value -= 1/300;
          });
        } else if (_progress.value > 0 && _progress.value < 1/300) {
          setState(() {
            _progress.value = 0;
          });
        }
      }

      if (detectShake(_path)) {
        debugPrint('Shake detected!');
        setState(() {
          _progress.value += 1/180; 
        });

        if (_progress.value >= 1) {
          setState(() {
            _progress.value = 1;
            task_completed='Il task è completato!';
          });
        }
      }
    });

    _progress.addListener(() async {
      if(_progress.value >= 1 && !isNavigating) {
        isNavigating = true;

        await Alarm.stop(widget.alarmId);
        await _gyroSub.cancel();
        
        if (mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PedometerApp(alarmId: widget.alarmId),
            settings: const RouteSettings(name: '/testPedometer'),
          ),);
        }

        isNavigating = false;
      }
    });
  }

  double standardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
  }

  bool detectShake(List<Offset3D> points) {
    if (points.length < 10) return false;

    final xStdev = standardDeviation(points.map((p) => p.dx).toList());
    final yStdev = standardDeviation(points.map((p) => p.dy).toList());
    final zStdev = standardDeviation(points.map((p) => p.dz).toList());

    const upperThresh = 250;
    const lowerThresh = 150;

    bool isX = xStdev>upperThresh&&yStdev<lowerThresh&&zStdev<lowerThresh;
    bool isY = yStdev>upperThresh&&xStdev<lowerThresh&&zStdev<lowerThresh;
    bool isZ = zStdev>upperThresh&&xStdev<lowerThresh&&yStdev<lowerThresh;

    final isShaking = (_axis==0)?isX:(_axis==1)?isY:isZ;
    
    return isShaking;
  }

  bool detectStandingStill(List<Offset3D> points) {
    if (points.length < 10) return false;

    final xStdev = standardDeviation(points.map((p) => p.dx).toList());
    final yStdev = standardDeviation(points.map((p) => p.dy).toList());
    final zStdev = standardDeviation(points.map((p) => p.dz).toList());

    final isStandingStill = (_axis==0)?xStdev<160:(_axis==1)?yStdev<150:zStdev<150;

    return isStandingStill;
  }

  @override
  void dispose() {
    debugPrint('+++++++++++++++++++++++++ DISPOSE ++++++++++++++++++++++++++');
    _gyroSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Data')),
      body: Stack(      
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child:SvgPicture.asset(
                    'assets/icons/shake.svg',
                    height: 200,
                    width: 200,
                  ),
                ),
                const SizedBox(height: 40),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 20,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text('${(_progress.value * 100).toStringAsFixed(0)}% completato',
                        style: const TextStyle(
                        fontSize: 18,
                      ),),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(task_completed,
                          style:  const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                 Center(
                  child: Text(
                    "Ruota il telefono sull'asse delle $_axis_text",
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.popUntil(context, (route) => route.settings.name == '/'),
        child: const Icon(Icons.backspace),
      ),
    );
  }
}
