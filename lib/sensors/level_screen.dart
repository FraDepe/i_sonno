import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_Sonno_Beta/sensors/pedometer_detector.dart';
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
  bool sentenceCaptured = false;

  bool alreadyStarted = false;

  Timer? _levelHoldTimer;

  bool showSuccess = false;
  bool showError = false;

  List<ColorSwatch<int>> badColors = [
    Colors.amber,
    Colors.amberAccent,
  ];
  List<ColorSwatch<int>> correctColors = [
    Colors.green,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();

    pickupSentence();
    generateRandomTargetTilt();
    _initSpeech();

    showSuccess = false;

    isCorrectLevelListener = () {
      if(isCorrectLevel.value) {
        if (_levelHoldTimer == null || !_levelHoldTimer!.isActive) {
          _levelHoldTimer = Timer(const Duration(seconds: 1), () {
            if(isCorrectLevel.value && (!alreadyStarted || (alreadyStarted && !sentenceCaptured))) {
              alreadyStarted = true;
              debugPrint(speechToTextAvailable.toString());
              if(speechToTextAvailable && !speechToText.isListening) {
                _startListening();
              }
            }
          });
        }
      } else {
        _levelHoldTimer?.cancel();
        _levelHoldTimer = null;
      }
    };

    //TODO  Gestire schermata tra il momendo in cui la frase viene controllata e il passaggio alla schermata successiva

    _accSub = accelerometerEventStream().listen((event) {
      final normalizedY = scaleY(event.y);
      _addSmoothedValue(normalizedY);
      setState(() {
        yPosition = _average(_yValues);
        isCorrectLevel.value = (_average(_yValues) - targetY).abs() < 0.014;
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

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    final preSpeechResult = result.recognizedWords;
  
    setState(() {
      speechResult = preSpeechResult;
    });

    sentenceCaptured = true;

    if(!speechToText.isListening) {
      if(isCorrectSentence()) {
        setState(() {
          showSuccess = true;
        });

        debugPrint('Lazio Merda');

        await Future.delayed(const Duration(seconds: 2));

        debugPrint('Forza Roma');
        //Navigator.popUntil(context, (route) => route.settings.name == '/');

        //^^^^^^^^^^^^^^^^^^^^^^^^^
        //TODO swap
        //vvvvvvvvvvvvvvvvvvvvvvvvv

        //isCorrectLevel.removeListener(isCorrectLevelListener);
        await _accSub?.cancel();
        _levelHoldTimer?.cancel();

        await Alarm.stop(widget.alarmId);
        debugPrint(mounted.toString());
        if (mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PedometerApp(alarmId: widget.alarmId),
            settings: const RouteSettings(name: '/testPedometer'),
          ),);
        }

      } else {
        
        setState(() {
          showError = true;
        });

        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          showError = false;
        });

        generateRandomTargetTilt();
        await pickupSentence();
        alreadyStarted = false;
        sentenceCaptured = false;
      }
    }
  }

  bool isCorrectSentence() {
    return sentence.toLowerCase() == speechResult.toLowerCase();
  }

  void generateRandomTargetTilt() {
    final random = Random();
    targetY = (random.nextDouble() * 1.6) - 0.8; // -0.8 to +0.8
  }

  Future<void> pickupSentence() async{
    final response = await rootBundle.loadString('assets/sentences.json');
    final cleaned = response.trim().replaceAll('{', '').replaceAll('}', '').replaceAll('\n', '');
    final entries = cleaned.split(',');
    if (entries.isEmpty) {
      sentence = 'Sempre forza Roma';
      return;
    }
    final randomEntry = entries[Random().nextInt(entries.length)];
    final parts = randomEntry.split(':');
    if (parts.length < 2) {
      sentence = 'Sempre forza Roma';
      return;
    }
    final phrase = parts.sublist(1).join(':').trim(); // caso con due punti nella frase (cosa che non accadrà mai)

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
    _levelHoldTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Screen'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(height: deviceHeight * 0.01),
          SizedBox(
            width: deviceWidth - 40,
            child: Text(
              'Fai combaciare le linee e ripeti la seguente frase:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: deviceWidth * 0.045),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: deviceWidth - 40,
            child: Text(
              sentence,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: deviceWidth * 0.045,
                color: const Color.fromARGB(255, 0, 75, 146),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment(0, targetY),
                  child: Container(
                    width: 350,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 76, 175, 80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 100),
                  alignment: Alignment(0, yPosition),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 250,
                    height: 11,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: getBackgroundColor(),
                        radius: 40,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if(showSuccess) ...[
                  const ColoredBox (
                    color: Color.fromRGBO(216, 240, 5, 0.63),
                    child: Center(
                      child: Text(
                        'Frase corretta',     //TODO oppure un'icona che probabilmente è più carina
                        style: TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                  ),
                ],
                if(showError) ...[
                  const ColoredBox (
                    color: Color.fromRGBO(240, 5, 5, 0.631),
                    child: Center(
                      child: Text(
                        'Frase sbagliata',     //TODO oppure un'icona che probabilmente è più carina
                        style: TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
