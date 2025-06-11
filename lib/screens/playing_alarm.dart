import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:i_Sonno_Beta/sensors/shake_detector.dart';
import 'package:logging/logging.dart';

class PlayingAlarmScreen extends StatefulWidget {
  const PlayingAlarmScreen({required this.alarmId, super.key});

  final int alarmId;

  @override
  _PlayingAlarmScreen createState() => _PlayingAlarmScreen();
}

class _PlayingAlarmScreen extends State<PlayingAlarmScreen> {
  static final _log = Logger('PlayingAlarmScreen');
  
  StreamSubscription<AlarmSet>? _ringingSubscription;

  @override
  void initState() {
    super.initState();
    _ringingSubscription = Alarm.ringing.listen((alarms) {
      if (alarms.containsId(widget.alarmId)) return;
      _log.info('Alarm ${widget.alarmId} stopped ringing.');
      _ringingSubscription?.cancel();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>  SensorApp(alarmId: widget.alarmId,),
      settings: const RouteSettings(name: '/playingAlarm/firstTask'),
    ),);
    
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 70, 52, 15),
      body: Center(
        child: ElevatedButton(
          onPressed: _stopAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text(
            'Inizia il task',
            style: TextStyle(fontSize: 24),),
        ),
      ),
    );
  }
}
