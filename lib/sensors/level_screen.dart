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
import 'package:volume_controller/volume_controller.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({required this.alarmId, super.key});

  final int alarmId;

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  late final VolumeController _volumeController;
  late final StreamSubscription<double> _subscription;
  double _currentVolume = 0;
  double _volumeValue = 0;
  bool _isMuted = false;

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
  Timer? _restoreVolumeTimer;

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

  bool _handledSpeech = false;

  @override
  void initState() {
    super.initState();

    initVolumeController();
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
    _currentVolume = await _volumeController.getVolume();
    if (_volumeValue > 0.2) {
      await _volumeController.setVolume(_currentVolume * 0.2);
    } else {
      _currentVolume = 0.7;
    }
    sentenceCaptured = false;
    speechResult = '';

    _restoreVolumeTimer?.cancel();
    _restoreVolumeTimer = Timer(const Duration(seconds: 8), () async {
      final current = await _volumeController.getVolume();
      if (current < 0.35) {
        await _volumeController.setVolume(_currentVolume);
      }
    });

    await speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        partialResults: false,
      )
    );

  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    final preSpeechResult = result.recognizedWords;

    speechResult = preSpeechResult;

    if (preSpeechResult.isNotEmpty) {
      sentenceCaptured = true;
    }
    
    _restoreVolumeTimer?.cancel();

    if(isCorrectSentence()) {
      setState(() {
        showSuccess = true;
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      await _accSub?.cancel();
      _levelHoldTimer?.cancel();

      await Alarm.stop(widget.alarmId);

      await _volumeController.setVolume(_currentVolume);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PedometerApp(alarmId: widget.alarmId),
            settings: const RouteSettings(name: '/testPedometer'),
          ),);
        }
      });

    } else {
      
      setState(() {
        showError = true;
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      await _volumeController.setVolume(_currentVolume);

      setState(() {
        showError = false;
      });

      generateRandomTargetTilt();
      await pickupSentence();
      alreadyStarted = false;
      sentenceCaptured = false;
    }
  }

  bool isCorrectSentence() {
    return sentence.toLowerCase() == speechResult.toLowerCase();
  }

  void generateRandomTargetTilt() {
    final random = Random();
    targetY = (random.nextDouble() * 1.6) - 0.8; // -0.8 to +0.8
  }

  Future<void> pickupSentence() async {
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

  void initVolumeController() {
    _volumeController = VolumeController.instance;
    _volumeController.showSystemUI = false;
    _subscription = _volumeController.addListener((volume) {
      _volumeValue = volume;
    });

    _volumeController.isMuted().then((isMuted) {
      _isMuted = isMuted;
    });
  }

  @override
  void dispose() {
    debugPrint('------------------------- Dispose ---------------------------');
    isCorrectLevel.removeListener(isCorrectLevelListener);
    _accSub?.cancel();
    _levelHoldTimer?.cancel();
    _subscription.cancel();
    _restoreVolumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Livella'),
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
                  ColoredBox (
                    color: const Color.fromRGBO(255, 255, 255, 0),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                        size: deviceWidth * 0.5,
                      ),
                    ),
                  ),
                ],
                if(showError) ...[
                  ColoredBox (
                    color: const Color.fromRGBO(255, 255, 255, 0),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: Colors.red,
                        size: deviceWidth * 0.5,
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
