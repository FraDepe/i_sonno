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

class _PedometerAppState extends State<PedometerApp> {

  Timer? _timer;
  Timer? _alarmTimer;

  late Stream<PedestrianStatus> _pedestrianStatusStream;
  PedestrianStatus? _status;

  Queue<double> accBuffer = Queue();
  final int bufferSize = 20;
  bool isReallyWalking = false;
  StreamSubscription? _accSub;

  bool isWalking = false;
  String task_completed = '';
  bool isNavigating = false;

  final ValueNotifier<double> _progress = ValueNotifier(0);
  late VoidCallback _progressListener;
  DateTime? _nextAlarmTime;

  @override
  void initState() {
    super.initState();

    _progress.value = 0.0;

    _progressListener = () async {
      if(_progress.value >= 1 && !isNavigating) {
        isNavigating = true;

        _timer?.cancel();
        await _accSub?.cancel();

        for (var i = 1; i < 5; i++) {
          final id = widget.alarmId + i;
          await Alarm.stop(id);
        }

        Navigator.popUntil(context, (route) => route.settings.name == '/');

        isNavigating = false;
      }
    };

    _progress.addListener(_progressListener);

    _initPedometer();
    _initAccelerometer();

    Alarm.getAlarm(widget.alarmId + 1).then((alarm) {
      _nextAlarmTime = alarm?.dateTime;
    });

    
    _alarmTimer = Timer.periodic(const Duration(seconds:1),(timer){
        final now = DateTime.now();
        if(!(_nextAlarmTime==null) &&now.isAfter(_nextAlarmTime!.subtract(const Duration(seconds: 5))) && !isNavigating && now.isBefore(_nextAlarmTime!)) {
          isNavigating = true;

          _timer?.cancel();
          _accSub?.cancel();

          Navigator.popUntil(context, (route) => route.settings.name == '/');

          isNavigating = false;
        }
      });
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

  //Magari farlo periodico ogni x ms
  void _onStatusChanged(PedestrianStatus status) {
    _status = status;      

    if (status.status == 'walking' && isReallyWalking) {
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

  return stDev > 1 && stDev < 2.3;
}

  void _startProgressTimer() {
    _timer?.cancel(); // ferma un eventuale timer precedente
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { 
      if (_status?.status == 'walking' && !isNavigating) {
        if (mounted) {
          setState(() {
            isWalking = true;
            _progress.value += 1/40;
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
    _alarmTimer?.cancel();
    _timer?.cancel();
    _accSub?.cancel();

    _progress.removeListener(_progressListener);
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
