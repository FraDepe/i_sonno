import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:i_sonno/router/homeRouter.dart';
import 'package:i_sonno/screen/alarms_screen.dart';
import 'package:i_sonno/screen/overlay_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  runApp(const AlarmApp());
}


@pragma('vm:entry-point') // Required so Dart does not tree-shake this method
void overlayMain() {
  runApp(const OverlayApp());
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      title: 'iSonno',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 110, 63, 63)),
      ),
      home: const HomeRouter(), // Router per gestire la schermata da aprire
    );
  }
}
