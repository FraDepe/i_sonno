import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:i_sonno/screen/add_alarm_screen.dart';
import 'package:i_sonno/model/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:i_sonno/sensors/shake_detector.dart';
import 'package:i_sonno/sensors/pedometer_detector.dart';
import 'package:i_sonno/service/local_notifications.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key, required this.title});

  final String title;

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}


class _AlarmsScreenState extends State<AlarmsScreen> {
  List<Alarm> alarms = [];

  void _addAlarm(Alarm alarm) async {
    setState(() {
      alarms.add(alarm);
    });
    AndroidAlarmManager.cancel(0);
    final dt = DateTime.now();
    await AndroidAlarmManager.oneShotAt(
      DateTime(dt.year, dt.month, dt.day, alarm.time.hour, alarm.time.minute),
      0, testCallback,
      wakeup: true);
      //Manca exact (che forse possiamo pure omettere)
  }

  void _toggleAlarm(int index, bool value) {
    setState(() {
      alarms[index].isActive = value;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(widget.title),
      ),
      body:  Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final newAlarm = await Navigator.push(
                    context, MaterialPageRoute(
                      builder: (context) => SensorApp.playerLess(),
                      settings: RouteSettings(name: "/testSensors")
                    )
                );
                if (newAlarm != null) {
                  _addAlarm(newAlarm);
                }
              },
              child: Text('Sensors'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final newAlarm = await Navigator.push(
                    context, MaterialPageRoute(
                      builder: (context) => PedometerApp(),
                      settings: RouteSettings(name: "/testPedometer")
                    )
                );
                if (newAlarm != null) {
                  _addAlarm(newAlarm);
                }
              },
              child: Text('Pedometer'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                LocalNotifications.sendSimpleNotification();
              },
              child: Text('Notificami tutto'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                var alarm = alarms[index];
                return Card(
                  //color: Colors.deepPurple,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    title: Text(
                      alarm.time.format(context),
                      style: TextStyle(fontSize: 36),
                    ),
                    subtitle: Text(
                      alarm.days.join(" "),
                      style: TextStyle(),
                    ),
                    trailing: Switch(
                      value: alarm.isActive,
                      onChanged: (value) => _toggleAlarm(index, value),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newAlarm = await Navigator.push(
            context, MaterialPageRoute(
              builder: (context) => AddAlarmScreen(),
              settings: RouteSettings(name: "/addAlarm")
            )
            );
            if (newAlarm != null) {
              _addAlarm(newAlarm);
            }
        },
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

}

@pragma('vm:entry-point')
void testCallback(int id) async {
  debugPrint("Mi hai rotto il cazzo");

  final intent = AndroidIntent(
    action: 'ACTION_PLAY_ALARM',
    //category: 'android.intent.category.LAUNCHER',
    package: 'com.example.i_sonno',
    componentName: 'com.example.i_sonno.MainActivity',
    flags: <int>[
      268435456, // FLAG_ACTIVITY_NEW_TASK
      536870912, // FLAG_ACTIVITY_CLEAR_TOP
      67108864   // FLAG_ACTIVITY_SINGLE_TOP
    ],
  );
  await intent.launch();
}