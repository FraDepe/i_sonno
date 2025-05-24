import 'dart:async' as dartAsync;

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerApp extends StatefulWidget {
  const PedometerApp({super.key});

  @override
  _PedometerAppState createState() => _PedometerAppState();
}

class _PedometerAppState extends State<PedometerApp> {

  dartAsync.Timer? _timer;

  late Stream<PedestrianStatus> _pedestrianStatusStream;
  PedestrianStatus? _status;

  static double _progress = 0.0;
  String task_completed = "";


  @override
  void initState() {
    super.initState();
    _initPedometer();
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

    if (status.status == 'walking') {
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

  void _startProgressTimer() {
    _timer?.cancel(); // ferma un eventuale timer precedente
    _timer = dartAsync.Timer.periodic(Duration(seconds: 1), (_) {
      if (_status?.status == 'walking') {
        setState(() {
          _progress += 1/200;
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


