import 'package:flutter/material.dart';
import 'package:i_sonno/model/alarm.dart';
import 'package:i_sonno/widget/multi_select.dart';
import 'package:file_picker/file_picker.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  _AddAlarmScreenState createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  TimeOfDay selectedTime = TimeOfDay(hour: 6, minute: 0);
  List<String> selectedDays = []; //Oggi o domani, in base all'orario scelto
  String ringtone = '';
  bool vibration = true;

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!);
      },
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void _showMultiSelection() async {
     
    final List<String> dayList = [
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica'
    ];
    
    final List<String>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelect(items: dayList);
      }
    );

    if (results != null) {
      setState(() {
        selectedDays = results;
      });
    }
  }

  Future<void> _selectRingtone() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav']
    );

    if (result != null) {
      ringtone = result.files.first.path!;
    }
  }

  void _toggleVibration(value) {
    setState(() {
      vibration = value;
    });
  }

  void _submit() {
    Navigator.pop(
      context,
      Alarm(0, selectedTime, selectedDays, ringtone), //Da capire come si comporta il construttore se gli vengono passati parametri null
                                                      // c'è da gestire anche la generazione degli id
    );
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(title: Text('Nuova Sveglia'), backgroundColor: const Color.fromARGB(255, 131, 110, 110)),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            SizedBox(
              width: deviceWidth * 0.7,
              height: deviceHeight * 0.08,
              child: TextButton(
                onPressed: _pickTime,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber),
                  ),
                ),
                child: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: deviceWidth * 0.06, color: Colors.black),
                ),
              ),
            ),
            Divider(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _showMultiSelection,
                  child: const Text("Ripeti") //ricorda che se non viene selezionato nulla => autoDelete = true
                ),
                Wrap(
                  spacing: deviceWidth * 0.03,
                  children: selectedDays.map((day) => 
                    Chip(
                      label: Text(day.substring(0,3)),
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    )
                  ).toList(),
                ),
              ],
            ),
            Divider(
              height: 30
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _selectRingtone,
                  child: const Text("Suoneria") //ricorda che se non viene selezionato nulla => ringtone = assets/Default.mp3
                ),
                Text(ringtone)
              ],
            ),
            Divider(
              height: 30
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Vibrazione"),
                Switch(
                  value: vibration,
                  onChanged: _toggleVibration
                )
              ],
            ),
            Divider(
              height: 30
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFA726)),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFA726)),
                  child: Text('Salva'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
