import 'dart:io';
import 'package:flutter/material.dart';
import 'package:i_sonno/global.dart' as global;
import 'package:flutter/services.dart';
import 'package:i_sonno/sensors/get_sensors_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayingAlarmScreen extends StatefulWidget {
  const PlayingAlarmScreen({super.key});

  @override
  _PlayingAlarmScreen createState() => _PlayingAlarmScreen();
}

class _PlayingAlarmScreen extends State<PlayingAlarmScreen> {
  final player = AudioPlayer();

  //Funzione che scrive l'asset suoneria su file
  Future<void> playAssetAsFile(AudioPlayer player, String assetPath) async {

  final byteData = await rootBundle.load(assetPath);

  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/temp_audio.mp3');

  await file.writeAsBytes(byteData.buffer.asUint8List());

  await player.setFilePath(file.path);
  await player.play();
}

  @override
  void initState() {
    _startAlarm();
    super.initState();
  }

  void _startAlarm() async {
    try {
      await playAssetAsFile(player, 'assets/Default.mp3');
      //await player.setClip(start: Duration(seconds: 0), end: Duration(seconds: 15));
      //await player.play();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void disposeAlarm() {
    player.dispose();
    super.dispose();
  }

  void _stopAlarm() async {
    //await player.stop();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>  SensorApp(player: player),
      settings: RouteSettings(name: "/playingAlarm/firstTask")
    ));
    
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
            'Inizia il task',
            style: TextStyle(fontSize: 24),),
        ),
      )
    );
  }
}