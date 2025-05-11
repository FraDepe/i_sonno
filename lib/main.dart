import 'package:flutter/material.dart';
import 'package:i_sonno/screen/add_alarm_screen.dart';
import 'package:i_sonno/model/alarm.dart';

void main() {
  runApp(const iSonno());
}


class iSonno extends StatelessWidget {
  const iSonno({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake Me App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 110, 63, 63)),
      ),
      home: AlarmsScreen(title: 'Sveglie'), // TODO Aggiungi gestione delle traduzioni
    );
  }
}


class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key, required this.title});

  final String title;

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}


class _AlarmsScreenState extends State<AlarmsScreen> {
  List<Alarm> alarms = [];

  void _addAlarm(Alarm alarm) {
    setState(() {
      alarms.add(alarm);
    });
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
      body: ListView.builder(
        itemBuilder: (context, index) {
          var alarm = alarms[index];
          return Card(
            color: Color(0xFF1E1E1E),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                alarm.time.format(context), // Togli AM e PM
                style: TextStyle(fontSize: 36, color: Colors.white70),
              ),
              subtitle: Text(
                alarm.days.join(" "), // Mostriamo le prime 3 lettere del giorno
                style: TextStyle(color: Colors.white54),
              ),
              trailing: Switch(
                value: alarm.isActive,
                onChanged: (value) => _toggleAlarm(index, value),
                activeColor: Color(0xFFFFA726)
              ),
            )
          );
        },
        itemCount: alarms.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newAlarm = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddAlarmScreen())
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
