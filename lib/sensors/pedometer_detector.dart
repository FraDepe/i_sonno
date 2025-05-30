import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';



class PedometerApp extends StatefulWidget {
  const PedometerApp({super.key});

  @override
  _PedometerAppState createState() => _PedometerAppState();
}

//FIXME spostare il calcolo della camminata in un widget, non nell'intera schermata. Migliora le performance
//inoltre si potrebbe chiamare il controllo isReallyWalking meno volte
class _PedometerAppState extends State<PedometerApp> {

  Timer? _timer;

  late Stream<PedestrianStatus> _pedestrianStatusStream;
  PedestrianStatus? _status;

  Queue<double> accBuffer = Queue();
  final int bufferSize = 20;
  bool isReallyWalking = false;
  StreamSubscription? _accSub;

  static double _progress = 0.0;
  String task_completed = "";


  @override
  void initState() {
    super.initState();
    _progress = 0;
    _initPedometer();
    _initAccelerometer();
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (status != PermissionStatus.granted) {
      print("Permission not granted!");
      return;
    }

    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(_onStatusChanged, onError: _onError);
  }

  void _onStatusChanged(PedestrianStatus status) {
    setState(() {
      _status = status;      
    });

    if (status.status == 'walking' && isReallyWalking) {
      _startProgressTimer();
    } else {
      _stopProgressTimer();
    }
  }

  void _onError(error) {
    print('Pedestrian Status error: $error');
    setState(() {
      _status = null;
    });
  }

  void _initAccelerometer() {
    _accSub = accelerometerEventStream().listen((event) {
      double acc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      accBuffer.add(acc);
      if (accBuffer.length > bufferSize) {
        accBuffer.removeFirst();
      }

      isReallyWalking = isMovementRegular();
    });
  }

  bool isMovementRegular() {
  if (accBuffer.length < bufferSize) return false;

  final mean = accBuffer.reduce((a, b) => a + b) / accBuffer.length;
  final variance = accBuffer
      .map((a) => pow(a - mean, 2))
      .reduce((a, b) => a + b) / accBuffer.length;
  final stDev = sqrt(variance);

  debugPrint(stDev.toString());
  // Gioca con questo valore in base a test reali
  return stDev > 0.8 && stDev < 1.8;
}

  void _startProgressTimer() {
    _timer?.cancel(); // ferma un eventuale timer precedente
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_status?.status == 'walking') {
        setState(() {
          _progress += 1/100;
          if (_progress > 1) {
            _progress = 1;
          }
        });
      }
    });
  }

  void _stopProgressTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accSub?.cancel();
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


