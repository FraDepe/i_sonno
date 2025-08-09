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
        secondsRemaining = 6;
        countdownTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            setState(() {
              countdownStarted = true;
            });
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
            }
          }
        );
      } else {
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
        automaticallyImplyLeading: false,
      ),
      body: Listener(
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 1,
                  colors: [Color.fromARGB(255, 244, 216, 54),Color.fromARGB(255, 255, 243, 82)],
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                actualFingers.value == targetFingers ? 
                'Mantieni le dita sullo schermo' : 
                'Metti sullo schermo $targetFingers dita',
                style: const TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Sullo schermo ci sono ${actualFingers.value} dita',
                style: const TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
            if (countdownStarted) ...[
              Positioned(
                top: 300,
                left: 185,
                child: Text(
                  '$secondsRemaining',
                  style: const TextStyle(color: Colors.black, fontSize: 100),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
