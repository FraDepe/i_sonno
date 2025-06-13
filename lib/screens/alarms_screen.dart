import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:i_Sonno_Beta/screens/add_alarm_screen.dart';
import 'package:i_Sonno_Beta/screens/playing_alarm.dart';
import 'package:i_Sonno_Beta/sensors/pedometer_detector.dart';
import 'package:i_Sonno_Beta/services/alarm_state.dart';
import 'package:i_Sonno_Beta/services/notifications.dart';
import 'package:i_Sonno_Beta/services/permission.dart';
import 'package:intl/intl.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}


class _AlarmsScreenState extends State<AlarmsScreen> {
  List<AlarmSettings> alarms = [];
  Notifications? notifications;

  static StreamSubscription<AlarmSet>? ringSubscription;
  static StreamSubscription<AlarmSet>? updateSubscription;


  @override
  void initState() {
    super.initState();
    AlarmPermissions.checkNotificationPermission().then(
      (_) => AlarmPermissions.checkAndroidScheduleExactAlarmPermission().then(
        (_) => AlarmPermissions.checkActivityPermission(),),
    );

    debugPrint('Init state');
    unawaited(loadAlarms());
    ringSubscription ??= Alarm.ringing.listen(ringingAlarmsChanged);
    updateSubscription ??= Alarm.scheduled.listen((_) {
      debugPrint('Subscription scheduled');
      unawaited(loadAlarms());
    });
    notifications = Notifications();
  }

  Future<void> loadAlarms() async {
    final updatedAlarms = await Alarm.getAlarms();
    //debugPrint('Load alarms: $updatedAlarms');
    updatedAlarms..sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1)
      ..removeWhere((item) => item.payload == 'hidden');
    setState(() {
      alarms = updatedAlarms;     
    });
  }

  Future<void> ringingAlarmsChanged(AlarmSet alarms) async {
    debugPrint('Ringing pre ringing screen');
    if (alarms.alarms.isEmpty || AlarmState.isAlarmActive) return;
    AlarmState.isAlarmActive = true;
    debugPrint('Ringing post check alarms');                                        
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            PlayingAlarmScreen(alarmId: alarms.alarms.first.id),
      ),
    );
    AlarmState.isAlarmActive = false;
    debugPrint('Return from Ringing screen');
    unawaited(loadAlarms());
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await Navigator.push(
      context, MaterialPageRoute(
        builder: (context) => AddAlarmScreen(alarmSettings: settings),
      ),
    );

    debugPrint('Return from add alarm');
    if (res != null && res == true) unawaited(loadAlarms());
  }

  String getNameOfDay(DateTime date) {
    final nameDay = DateFormat('EEEE').format(date);
    final ymdDate = DateFormat('dd/MM/yyyy').format(date);

    switch (nameDay) {
      case 'Monday':
        return 'Lunedì $ymdDate';
      case 'Tuesday':
        return 'Martedì $ymdDate';
      case 'Wednesday':
        return 'Mercoledì $ymdDate';
      case 'Thursday':
        return 'Giovedì $ymdDate';
      case 'Friday':
        return 'Venerdì $ymdDate';
      case 'Saturday':
        return 'Sabato $ymdDate';
      case 'Sunday':
        return 'Domenica $ymdDate';
      default:
        return ymdDate;
    }
  }

  @override
  void dispose() {
    debugPrint('disponse');
    ringSubscription?.cancel();
    updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Sveglie',
          style: TextStyle(color: Colors.white),),
      ),
      body:  Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context, MaterialPageRoute(
                    builder: (context) => const PedometerApp(alarmId: 0,),
                    settings: const RouteSettings(name: '/testPedometer'),
                  ),
                );
              },
              child: const Text('Pedometer'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return Card(
                  //color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    title: Text(
                      TimeOfDay.fromDateTime(alarm.dateTime).format(context),
                      style: const TextStyle(fontSize: 36),
                    ),
                    subtitle: Text(getNameOfDay(alarm.dateTime)),
                    trailing: const Icon(
                      IconData(0xe21a, fontFamily: 'MaterialIcons'),
                      applyTextScaling: true,
                    ),
                    onTap: () => navigateToAlarmScreen(alarm),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Aggiungi sveglia'),
        onPressed: () => navigateToAlarmScreen(null),
        elevation: 6,
        icon: const Icon(Icons.add),
      ),
    );
  }

}
