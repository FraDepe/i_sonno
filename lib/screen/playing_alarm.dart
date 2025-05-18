import 'dart:io';
import 'package:flutter/material.dart';
import 'package:i_sonno/global.dart' as global;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayingAlarmScreen extends StatefulWidget {
  const PlayingAlarmScreen({super.key});

  @override
  _PlayingAlarmScreen createState() => _PlayingAlarmScreen();
}

class _PlayingAlarmScreen extends State<PlayingAlarmScreen> {
  final player = AudioPlayer();

  @override
  void initState() {
    _startAlarm();
    super.initState();
  }

  void _startAlarm() async {
    try {
      await player.setAsset(global.defaultRingtone);
      await player.setClip(start: Duration(seconds: 0), end: Duration(seconds: 15));
      await player.play();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void disposeAlarm() {
    player.dispose();
    super.dispose();
  }

  void _stopAlarm() async {
    await player.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarmTriggered', false);

    if (mounted) {
      Navigator.of(context).pop();
    } else {
      exit(0);
    }
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
          child: Text(
            'Spegni sveglia',
            style: TextStyle(fontSize: 24),),
        ),
      )
    );
  }
}