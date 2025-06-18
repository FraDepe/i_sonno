import 'package:alarm/alarm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key, this.alarmSettings});

  final AlarmSettings? alarmSettings;

  @override
  _AddAlarmScreenState createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  bool loading = false;

  late bool creating;
  late DateTime selectedDateTime;
  late String nameOfTheDay;
  late bool loopAudio;
  late bool vibrate;
  late double? volume;
  late Duration? fadeDuration;
  late bool staircaseFade;
  late String assetAudio;

  @override
  void initState() {
    super.initState();
    creating = widget.alarmSettings == null;

    if (creating) {
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      nameOfTheDay = getNameOfDay(selectedDateTime);
      loopAudio = true;
      vibrate = true;
      volume = null;
      fadeDuration = null;
      staircaseFade = false;
      assetAudio = 'assets/white_lady.mp3';
    } else {
      selectedDateTime = widget.alarmSettings!.dateTime;
      nameOfTheDay = getNameOfDay(selectedDateTime);
      loopAudio = widget.alarmSettings!.loopAudio;
      vibrate = widget.alarmSettings!.vibrate;
      volume = widget.alarmSettings!.volumeSettings.volume;
      fadeDuration = widget.alarmSettings!.volumeSettings.fadeDuration;
      staircaseFade = widget.alarmSettings!.volumeSettings.fadeSteps.isNotEmpty;
      assetAudio = widget.alarmSettings!.assetAudioPath;
    }
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

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color.fromARGB(255, 17, 17, 17),
                dialHandColor: Colors.deepPurple,
                dialBackgroundColor: Colors.grey.shade900,
                hourMinuteColor: WidgetStateColor.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.deepPurple
                      : Colors.grey.shade900;
                }),
                hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white70;
                }),
                dayPeriodColor: Colors.deepPurple.withOpacity(0.5),
                dayPeriodTextColor: Colors.white,
                dialTextColor: Colors.white,
                entryModeIconColor: Colors.deepPurpleAccent,
                helpTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: Color(0xFF121212),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        selectedDateTime = now.copyWith(
          hour: time.hour,
          minute: time.minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }
        nameOfTheDay = getNameOfDay(selectedDateTime);
      });
    }
  }

  AlarmSettings buildAlarmSettings() {
    final id = creating
        ? DateTime.now().millisecondsSinceEpoch % 10000 + 1
        : widget.alarmSettings!.id;

    final volumeSettings = VolumeSettings.fixed(volume: volume);

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      assetAudioPath: assetAudio,
      volumeSettings: volumeSettings,
      androidStopAlarmOnTermination: false,
      notificationSettings: NotificationSettings(
        title: 'Sveglia',
        body: 'La sveglia sta suonando',
        icon: 'notification_icon',
      ),
    );

    return alarmSettings;
  }

  void saveAlarm() {
    if (loading) return;
    setState(() => loading = true);

    final original = buildAlarmSettings();
    final firstCopy = original.copyWith(
      dateTime: original.dateTime.add(const Duration(minutes: 5)),
      id: original.id + 1,
      payload: () => 'hidden',);
    final secondCopy = firstCopy.copyWith(
      dateTime: firstCopy.dateTime.add(const Duration(minutes: 5)),
      id: firstCopy.id + 1,
      payload: () => 'hidden',);
    final thirdCopy = secondCopy.copyWith(
      dateTime: secondCopy.dateTime.add(const Duration(minutes: 5)),
      id: secondCopy.id + 1,
      payload: () => 'hidden',);
    final fourthCopy = thirdCopy.copyWith(
      dateTime: thirdCopy.dateTime.add(const Duration(minutes: 5)),
      id: thirdCopy.id + 1,
      payload: () => 'hidden',);
    
    Alarm.set(alarmSettings: original)
      .then((res) {
        if (res) {
          Alarm.set(alarmSettings: firstCopy)
            .then((res) {
              if (res) {
                Alarm.set(alarmSettings: secondCopy)
                  .then((res) {
                    if (res) {
                      Alarm.set(alarmSettings: thirdCopy)
                        .then((res) {
                          if (res) {
                            Alarm.set(alarmSettings: fourthCopy)
                              .then((res) {
                                if (res && mounted) Navigator.pop(context, true);
                                setState(() => loading = false);
                              });
                          }
                        });
                    }
                  });
              }
            });
        }
      });
  }

  void deleteAlarm() {
    if(!creating) {
      Alarm.stop(widget.alarmSettings!.id).then((res) {
        if (res) {
          Alarm.stop(widget.alarmSettings!.id + 1).then((res) {
            if (res) {
              Alarm.stop(widget.alarmSettings!.id + 2).then((res) {
                if (res) {
                  Alarm.stop(widget.alarmSettings!.id + 3).then((res) {
                    if (res) {
                      Alarm.stop(widget.alarmSettings!.id + 4).then((res) {
                        if (res) {
                          if (res && mounted) Navigator.pop(context, true);
                        }
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectRingtone() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );

    if (result != null) {
      setState(() {
        assetAudio = result.files.first.path!;
      });
    }
  }

  String getRingtoneName(String ringtone) {
    debugPrint(ringtone);
    if (ringtone.split('/').last == 'white_lady.mp3') {
      return 'White Lady';
    }
    var ringtoneName = ringtone.split('/').last;
    ringtoneName = ringtoneName.replaceAll('.mp3', ''); 
    return ringtoneName.length < 30
      ? ringtoneName
      : '${ringtoneName.substring(0, 27)}...';
  }

  void toggleVibration() {
    setState(() {
      vibrate = !vibrate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Sveglia', style: TextStyle(color: Colors.white),)),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            SizedBox(
              width: deviceWidth * 0.7,
              height: deviceHeight * 0.20,
              child: TextButton(
                onPressed: _pickTime,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(100, 100),
                ),
                child: Text(
                  '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: deviceWidth * 0.08),
                  textScaler: const TextScaler.linear(1.7),
                ),
              ),
            ),
            SizedBox(
              height: deviceHeight * 0.015,
            ),
            Center(
              child: Text(
                nameOfTheDay,
                textScaler: const TextScaler.linear(1.3),
                style: const TextStyle(
                  color: Color.fromARGB(255, 209, 182, 255),
                ),
              ),
            ),
            SizedBox(
              height: deviceHeight * 0.04,
            ),
            const Divider(
              height: 10,
            ),
            InkWell(
              onTap: _selectRingtone,
              child: SizedBox(
                width: deviceWidth,
                height: deviceHeight * 0.06,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suoneria', textScaler: TextScaler.linear(1.2),),
                    Text(getRingtoneName(assetAudio), textScaler: const TextScaler.linear(1.2),),
                  ],
                ),
              ),
            ),
            const Divider(
              height: 10,
            ),
            InkWell(
              onTap: toggleVibration,
              child: SizedBox(
                width: deviceWidth,
                height: deviceHeight * 0.06,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vibrazione', textScaler: TextScaler.linear(1.2),),
                    Switch(
                      value: vibrate,
                      onChanged: (value) => setState(() => vibrate = value),
                      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return Colors.black;
                      }),
                      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green; // thumb when ON
                        }
                        return const Color.fromARGB(255, 163, 163, 163);
                      }),
                      trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green; // outline when ON
                        }
                        return const Color.fromARGB(255, 163, 163, 163);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(
              height: 10,
            ),
            SizedBox(
              height: deviceHeight * 0.035,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: deleteAlarm,
                  style: ElevatedButton.styleFrom(),
                  child: Text(creating ? 'Annulla' : 'Elimina'),
                ),
                ElevatedButton(
                  onPressed: saveAlarm,
                  style: ElevatedButton.styleFrom(),
                  child: const Text('Salva'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
