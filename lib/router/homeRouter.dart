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
        Future.delayed(Duration(milliseconds: 300), () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PlayingAlarmScreen(),
            settings: RouteSettings(name: "/playingAlarm")
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Uscire dall\'app?'),
          content: const Text('Vuoi davvero chiudere l\'app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Esci'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    },
    child: const AlarmsScreen(title: "Sveglie!")
  );
}
}