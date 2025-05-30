import 'package:flutter/material.dart';

class Alarm {
  int id;
  TimeOfDay time;
  List<String> days; // Da lunedì a domenica
  bool isActive;
  String label;
  bool vibration;
  String ringtonePath;
  // bool autoDelete;
  //qualcosa per programmare nel futuro la sveglia (oltre i sette giorni della settimana)

    Alarm(
      this.id,
      this.time,
      this.days, // default oggi o domani in base all'orario OR required
      this.ringtonePath,
      [
        this.isActive = true,
        this.label = "Sveglia",
        this.vibration = false,
      ]
    );
    /*
    Alarm({
      required this.time,
      required this.days,
      this.isActive = true,
      this.label = "Sveglia",
      this.vibration = false,
      this.ringtonePath = globals.defaultRingtone
    });
    */
}