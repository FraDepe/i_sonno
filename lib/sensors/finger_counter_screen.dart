import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class FingerCounterScreen extends StatefulWidget {
  const FingerCounterScreen({required this.alarmId, super.key});

  final int alarmId;

  @override
  _FingerCounterScreenState createState() => _FingerCounterScreenState();
}

class _FingerCounterScreenState extends State<FingerCounterScreen> {

  int targetFingers = 0;

  final ValueNotifier<int> actualFingers = ValueNotifier(0);
  late VoidCallback actualFingersListener;

  int secondsRemaining = 6;
  Timer? countdownTimer;

  bool countdownStarted = false;

  @override
  void initState() {
    super.initState();

    targetFingers = Random().nextInt(5)+1;

    actualFingersListener = () {
      if(actualFingers.value == targetFingers) {
        secondsRemaining = 5;
        setState(() {
          countdownStarted = true;
        });
        countdownTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if(secondsRemaining > 1) {
              setState(() {
                secondsRemaining--;
              });
            } else {
              setState(() {
                secondsRemaining--;
                countdownStarted = false;
              });
              timer.cancel();

              //await Alarm.stop(widget.alarmId);
              //if (mounted) {
              //  await Navigator.of(context).push(MaterialPageRoute(
              //    builder: (_) => PedometerApp(alarmId: widget.alarmId),
              //    settings: const RouteSettings(name: '/testPedometer'),
              //  ),);
              //}
            }
          }
        );
      } else {
        setState(() {
          countdownStarted = false;
        });
        countdownTimer?.cancel();
      }
    };

    actualFingers.addListener(actualFingersListener);
  }

  @override
  void dispose() {
    debugPrint('------------------------- Dispose ---------------------------');
    actualFingers.removeListener(actualFingersListener);
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Count finger Screen'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() {
            actualFingers.value++;
          });
        },
        onPointerUp: (_) {
          setState(() {
            actualFingers.value--;
          });
        },
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: SizedBox(
                width: deviceWidth - 40,
                child: Text(
                  actualFingers.value == targetFingers ? 
                  'Mantieni le dita sullo schermo' : 
                  'Metti sullo schermo $targetFingers dita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: deviceWidth * 0.045,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: SizedBox(
                width: deviceWidth - 40,
                child: Text(
                  'Sullo schermo ci sono ${actualFingers.value} dita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: deviceWidth * 0.045,
                  ),
                ),
              ),
            ),
            if (countdownStarted) ...[
              Positioned(
                top: 300,
                left: 185,
                child: Text(
                  '$secondsRemaining',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 193, 7),
                    fontSize: 100,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
