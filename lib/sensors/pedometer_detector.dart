import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerApp extends StatefulWidget {
  const PedometerApp({super.key});

  @override
  _PedometerAppState createState() => _PedometerAppState();
}

class _PedometerAppState extends State<PedometerApp> {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
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

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
  }

  void _onStepCount(StepCount event) {
    print('Steps: ${event.steps}');
    setState(() {
      _steps = event.steps;
      _progress += 1/200;
      if (_progress >= 1) {
            _progress = 1;
            task_completed="Il task è completato!";
          }
      
        if (_progress < 1) {
          if (_progress > 1/300) {
            _progress -= 1/300;
            debugPrint("Movite");
          } else if (_progress > 0 && _progress < 1/300) {
            _progress = 0;
          }
        }
    });
  }

  void _onStepCountError(error) {
    print('Step Count Error: $error');
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


