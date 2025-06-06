import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;

class Offset3D {
  final double dx;
  final double dy;
  final double dz;

  const Offset3D(this.dx, this.dy, this.dz);

  Offset3D operator *(double scale) => Offset3D(dx * scale, dy * scale, dz * scale);

  @override
  String toString() => 'Offset3D(x: $dx, y: $dy, z: $dz)';
}

class SensorApp extends StatefulWidget {
  final AudioPlayer? player;

  const SensorApp({Key? key, required this.player}) : super(key: key);

  const SensorApp.playerFull(AudioPlayer player, {Key? key}) : this(key: key, player: player);

  const SensorApp.playerLess({Key? key}) : this(key: key, player: null);
  
  @override
  _SensorAppState createState() => _SensorAppState();
}

class _SensorAppState extends State<SensorApp> {

  final int bufferSize = 10;

  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    //fixme Perchè usiamo due import uguali ma uno ha un nome?
    //E soprattutto perchè se usiamo solamente l'import senza nome l'app va in Stack Overflow?
    return sensors.gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }

  late StreamSubscription<GyroscopeEvent> _gyroSub;

  final List<Offset3D> _path = [Offset3D(200, 400, 0)];
  final double scaleFactor = 60.0;
  String task_completed = "";
  int _axis = 0;
  String _axis_text = "";
  static double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _axis = Random().nextInt(3);
    _axis_text = (_axis==0)?"x":(_axis==1)?"y":"z";
    _progress=0.0;
    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {

      final Offset3D point = Offset3D(event.x, event.y, event.z) * scaleFactor;

      setState(() {
        
        _path.add(point);

        if (_path.length > bufferSize) {
          _path.removeAt(0);
        }

        if (_progress < 1 && detectStandingStill(_path)) {
          if (_progress > 1/300) {
            _progress -= 1/300;
            debugPrint("Movite");
          } else if (_progress > 0 && _progress < 1/300) {
            _progress = 0;
          }
        }

        if (detectShake(_path)) {
          print("Shake detected!");
          _progress += 1/200;

          if (_progress >= 1) {
            _progress = 1;
            task_completed="Il task è completato!";
            widget.player?.stop();
          }
        }
      });
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

    int upperThresh = 250;
    int lowerThresh = 150;

    bool isX = xStdev>upperThresh&&yStdev<lowerThresh&&zStdev<lowerThresh;
    bool isY = yStdev>upperThresh&&xStdev<lowerThresh&&zStdev<lowerThresh;
    bool isZ = zStdev>upperThresh&&xStdev<lowerThresh&&yStdev<lowerThresh;

    print("x:"+xStdev.toString()+"y:"+yStdev.toString()+"z:"+zStdev.toString());

    final isShaking = (_axis==0)?isX:(_axis==1)?isY:isZ;
    
    return isShaking;
  }

  bool detectStandingStill(List<Offset3D> points) {
    if (points.length < 10) return false;

    final xStdev = standardDeviation(points.map((p) => p.dx).toList());
    final yStdev = standardDeviation(points.map((p) => p.dy).toList());
    final zStdev = standardDeviation(points.map((p) => p.dz).toList());

    final isStandingStill = (_axis==0)?xStdev<160:(_axis==1)?yStdev<150:zStdev<150;
    //todo capire se vogliamo avere un margine in cui la barra ne aumenta ne diminuisce

    return isStandingStill;
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
                  SizedBox(height: 60),
                  Center(
                    // Forse non è tanto uno shake ma più una rotazione (ruota il telefono...)
                    child: Text("Shakera il telefono sull'asse delle "+_axis_text+" al completamento della barra")
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
                        ),
                        SizedBox(height: 20),
                        Text('${(_progress * 100).toStringAsFixed(0)}% completato'),
                        SizedBox(height: 60),
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

//FIXME Ci serve o era per disegnare il plot dei sensori?
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

