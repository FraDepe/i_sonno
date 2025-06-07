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
  List<String> days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì","Venerdì","Sabato","Domenica"];
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
        return MultiSelect(items: dayList, initiallySelected: selectedDays);
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
      appBar: AppBar(title: Text('Nuova Sveglia')),
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
                    side: BorderSide(),
                  ),
                  minimumSize: Size(100,100)
                ),

                child: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: deviceWidth * 0.06),
                ),
              ),
            ),
            Divider(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ripeti'),
                GestureDetector(
                onTap: () {
                  _showMultiSelection();
                },
                child: Container(
                  child:Wrap(
                    spacing: deviceWidth * 0.03,
                    children: days.map((day) =>   
                      Container(
                        child: (selectedDays.contains(day))?Text(day.substring(0,2), style:TextStyle(color: Colors.white)):Text(day.substring(0,2), style:TextStyle(color: Colors.grey)),
                      )
                    ).toList(),
                  ),
                )
              )
              ],
            ),
            Divider(
              height: 30
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Suoneria"),
                Spacer(),
                ElevatedButton(
                  onPressed: _selectRingtone,
                  child: const Text("Default"), //ricorda che se non viene selezionato nulla => ringtone = assets/Default.mp3
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.deepPurple)
                  )             
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
                  onChanged: _toggleVibration,
                  trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black; // track when ON
                      }
                      return Colors.black; // track when OFF
                    }),
                    thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        print("on");
                        return Colors.green; // thumb when ON
                      }
                      return Colors.white; // thumb when OFF
                    }),
                    trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.green; // outline when ON
                      }
                      return Colors.white; // outline when OFF
                    }),
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
                  style: ElevatedButton.styleFrom(),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(),
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
