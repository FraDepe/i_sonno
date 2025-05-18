import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_sonno/screen/alarms_screen.dart';
import 'package:i_sonno/screen/playing_alarm.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  static const platform = MethodChannel('alarm_channel');

  @override
  void initState() {
    super.initState();

    platform.setMethodCallHandler((call) async {
      if (call.method == "openAlarmPage") {
        // ritardiamo leggermente per essere sicuri che il context sia disponibile
        Future.delayed(Duration(milliseconds: 300), () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlayingAlarmScreen(),
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AlarmsScreen(title: 'Sveglie');
  }
}
