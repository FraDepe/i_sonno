import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';


class PedometerApp extends StatefulWidget {
  const PedometerApp({required this.alarmId, super.key});

  final int alarmId;

  @override
  _PedometerAppState createState() => _PedometerAppState();
}

//FIXME spostare il calcolo della camminata in un widget, non nell'intera schermata. 
//Migliora le performance
//inoltre si potrebbe chiamare il controllo isReallyWalking meno volte
class _PedometerAppState extends State<PedometerApp> {

  Timer? _timer;

  late Stream<PedestrianStatus> _pedestrianStatusStream;
  PedestrianStatus? _status;

  Queue<double> accBuffer = Queue();
  final int bufferSize = 20;
  bool isReallyWalking = false;
  StreamSubscription? _accSub;

  bool isWalking = false;
  String task_completed = '';
  bool isNavigating = false;

  static final ValueNotifier<double> _progress = ValueNotifier(0);

  @override
  void initState() {
    super.initState();

    _progress.value = 0.0;

    _progress.addListener(() {
      if(_progress.value >= 1 && !isNavigating) {
        isNavigating = true;

        _timer?.cancel();
        _accSub?.cancel();

        Alarm.stopAll(); //FIXME deve avere l'id della sveglia originale per poi spegnere quelle successive +1, +2, +3, +4 altrimenti le spegne tutte
        
        Navigator.popUntil(context, (route) => route.settings.name == '/');

        isNavigating = false;
      }
    });

    _initPedometer();
    _initAccelerometer();
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.status;
    if (status != PermissionStatus.granted) {
      debugPrint('Permission not granted!');
      return;
    }

    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(_onStatusChanged, onError: _onError);
  }

  void _onStatusChanged(PedestrianStatus status) {
    _status = status;      

    //if (status.status == 'walking' && isReallyWalking) {
    if (status.status == 'walking') {
      _startProgressTimer();
    } else {
      _stopProgressTimer();
    }
  }

  void _onError(error) {
    debugPrint('Pedestrian Status error: $error');
    _status = null;
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
  return stDev > 1 && stDev < 2.3;
}

  void _startProgressTimer() {
    _timer?.cancel(); // ferma un eventuale timer precedente
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { //FIXME prova con poco meno di un secondo
      if (_status?.status == 'walking') {
        if (mounted) {
          setState(() {
            isWalking = true;
            _progress.value += 1/8;
          });
        }

        if (_progress.value > 1) {
          if (mounted) {
            setState(() {
              _progress.value = 1;
            });
          }
        }

      }
    });
  }

  void _stopProgressTimer() {
    if (mounted) {
      setState(() {
        isWalking = false;
      });
    }
    _timer?.cancel();
  }

  @override
  void dispose() {
    debugPrint('------------------------- Dispose ---------------------------');
    _timer?.cancel();
    _accSub?.cancel();
    super.dispose();
  }

 
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Data')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Center(
                  // Forse non è tanto uno shake ma più una rotazione (ruota il telefono...)
                  child: Text('Cammina fino a completamento della barra'),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 20,
                        backgroundColor: Colors.grey[300],
                      ),const SizedBox(height: 20),
                      Text('${(_progress.value * 100).toStringAsFixed(0)}% completato'),
                      const SizedBox(height: 60),
                      Center(child: Text(task_completed)),
                      Icon(
                        isWalking ? Icons.directions_walk_rounded
                                  : Icons.accessibility_new_rounded,
                        size: 240,
                      ),
                    ],
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
