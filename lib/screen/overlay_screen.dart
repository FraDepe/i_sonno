import 'package:flutter/material.dart';
import 'package:i_sonno/global.dart' as global;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AlarmPlayer {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> start() async {
    try {
      await _player.setAsset(global.defaultRingtone);
      await _player.setClip(start: const Duration(seconds: 0), end: const Duration(seconds: 15));
      await _player.play();
    } catch (e) {
      debugPrint("Alarm error: $e");
    }
  }

  static Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarmTriggered', false);
  }
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {

    AlarmPlayer.start();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 70, 52, 15),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await AlarmPlayer.stop();
              await FlutterOverlayWindow.closeOverlay();

              // Optional: open app
              // await openMainApp(); // ← your intent logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Spegni sveglia',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}
