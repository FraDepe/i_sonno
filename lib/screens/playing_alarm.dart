import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:i_Sonno_Beta/sensors/shake_detector.dart';
import 'package:i_Sonno_Beta/services/alarm_state.dart';
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
      final currentRoute = ModalRoute.of(context)?.settings.name;
      debugPrint(currentRoute);
      if (alarms.containsId(widget.alarmId)) return;
      _log.info('Alarm ${widget.alarmId} stopped ringing.');
      _ringingSubscription?.cancel();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    AlarmState.isAlarmActive = false;
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
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
   return Scaffold(
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: deviceWidth * 0.7,
          height: deviceHeight * 0.20,
          child: Text(
            '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: deviceWidth * 0.1),
            textScaler: const TextScaler.linear(2.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40), // spacing between text and button
        ElevatedButton(
          onPressed: _stopAlarm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text(
            'Spegni sveglia',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ],
    ),
  ),
);
  }
}
