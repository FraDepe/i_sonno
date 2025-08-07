import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({required this.alarmId, super.key});

  final int alarmId;

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  StreamSubscription? _accSub;
  
  final Queue<double> _yValues = Queue<double>();
  static const int _smoothingWindow = 10;
  double yPosition = 0;

  double targetY = 0;

  String sentence = '';

  final ValueNotifier<bool> isCorrectLevel = ValueNotifier(false);
  late VoidCallback isCorrectLevelListener;

  SpeechToText speechToText = SpeechToText();
  bool speechToTextAvailable = false;
  String speechResult = '';

  bool alreadyStarted = false;

  List<ColorSwatch<int>> badColors = [
    Colors.red,
    Colors.redAccent,
  ];
  List<ColorSwatch<int>> correctColors = [  //TODO giallo? oppure facciamo in modo che la linea diventa unica (target + inclinazione) e dello stesso colore
    Colors.green,
    Colors.greenAccent,
  ];

//TODO Nonappena la linea è allineata con quella target, l'app comincia ad ascolare

  @override
  void initState() {
    super.initState();

    pickupSentence();
    generateRandomTargetTilt();
    _initSpeech();

    isCorrectLevelListener = () {      
      if(isCorrectLevel.value && !alreadyStarted) {
        alreadyStarted = true;
        debugPrint(speechToTextAvailable.toString());
        if (speechToTextAvailable) {
          _startListening();
        }
      }
    };

    //TODO  Gestire il caso della frase sbagliata e la schermata tra il momendo in cui la frase viene controllata e il passaggio alla schermata successiva

    _accSub = accelerometerEventStream().listen((event) {
      final normalizedY = scaleY(event.y);
      _addSmoothedValue(normalizedY);
      setState(() {
        yPosition = _average(_yValues);
        isCorrectLevel.value = (_average(_yValues) - targetY).abs() < 0.0135;
        //debugPrint((atan(_average(_yValues) * 9.8) * (180 / pi)).round().toString());
        debugPrint(isCorrectLevel.value.toString());
      });
    });

    isCorrectLevel.addListener(isCorrectLevelListener);
  }

  void _addSmoothedValue(double value) {
    _yValues.add(value);
    if (_yValues.length > _smoothingWindow) {
      _yValues.removeFirst();
    }
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double scaleY(double rawY) {
    return (rawY / 9.8).clamp(-1.0, 1.0);
  }

  double getXDotPosition(double xValue) {
    if (isCorrectLevel.value) {
      return 0;
    } else {
      return xValue;
    }
  }
  double getYDotPosition(double yValue) {
    if (isCorrectLevel.value) {
      return 0;
    } else {
      return yValue;
    }
  }

  bool isWithinTolerance(double value, double tolerance) {
    return value.abs() < tolerance;
  }

  Future<void> _initSpeech() async {
    final available = speechToText.initialize();
    await available.then((value) {
      speechToTextAvailable = value;
    });
  }

  Future<void> _startListening() async {
    await speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 4),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      speechResult = result.recognizedWords;
    });
  }

  void generateRandomTargetTilt() {
    final random = Random();
    targetY = (random.nextDouble() * 1.6) - 0.8; // -0.8 to +0.8
  }

  Future<void> pickupSentence() async{
    final response = await rootBundle.loadString('assets/sentences.json');
    final cleaned = response.trim().replaceAll('{', '').replaceAll('}', '').replaceAll('\n', '');
    final entries = cleaned.split(',');
    if (entries.isEmpty) return;              //FIXME capiamo cosa fare
    final randomEntry = entries[Random().nextInt(entries.length)];
    final parts = randomEntry.split(':');
    if (parts.length < 2) return;             //FIXME capiamo cosa fare
    final phrase = parts.sublist(1).join(':').trim(); // caso con due punti nella frase

    sentence = phrase.replaceAll('"', '').trim();
  }

  List<ColorSwatch<int>> getBackgroundColor() {
    return isCorrectLevel.value ? correctColors : badColors;
  }

  @override
  void dispose() {
    debugPrint('------------------------- Dispose ---------------------------');
    isCorrectLevel.removeListener(isCorrectLevelListener);
    _accSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Screen'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1,
                colors: getBackgroundColor(),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              'Target tilt: ${(atan(targetY * 9.8) * (180 / pi)).round()} °',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Positioned(
            top: 40,
            left: 175,
            child: Text(
              'Angolazione attuale: ${(atan(yPosition * 9.8) * (180 / pi)).round()} °',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: Text(
              'Frase: $sentence',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Positioned(
            top: 80,
            left: 20,
            child: Text(
              'Frase: $speechResult',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Align(
            alignment: Alignment(0, targetY),
            child: const Divider(
              color: Colors.white,
              thickness: 10,
              indent: 50,
              endIndent: 50,
            ),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 100),
            alignment: Alignment(0, yPosition),
            child: Container(
              width: 180,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
