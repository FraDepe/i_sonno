import 'dart:async';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:i_Sonno_Beta/sensors/pedometer_detector.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:volume_controller/volume_controller.dart';

class SortNumberScreen extends StatefulWidget {
  const SortNumberScreen({required this.alarmId, super.key});

  final int alarmId;

  @override
  _SortNumberScreenState createState() => _SortNumberScreenState(); 
}

class _SortNumberScreenState extends State<SortNumberScreen> {
  late int firstNumber;
  late int secondNumber;
  late int thirdNumber;
  late int fourthNumber;

  SpeechToText speechToText = SpeechToText();
  bool speechToTextAvailable = false;
  String speechResult = '';
  bool sentenceCaptured = false;

  late final VolumeController _volumeController;
  late final StreamSubscription<double> _subscription;
  double _currentVolume = 0;
  double _volumeValue = 0;
  bool _isMuted = false;

  Timer? _restoreVolumeTimer;

  bool showSuccess = false;
  bool showError = false;
  
  @override
  void initState() {
    super.initState();

    pickRandomNumber();
    _initSpeech();
    initVolumeController();
  }

  void pickRandomNumber() {
    final random = Random();
    setState(() {
      firstNumber = random.nextInt(10);
      secondNumber = random.nextInt(10);
      thirdNumber = random.nextInt(10);
      fourthNumber = random.nextInt(10);
    });
  }
  
  Future<void> _initSpeech() async {
    final available = speechToText.initialize();
    await available.then((value) {
      speechToTextAvailable = value;
    });
  }

  bool isCorrectSentence() {
    const numberNames = {
      0: 'zero',
      1: 'uno',
      2: 'due',
      3: 'tre',
      4: 'quattro',
      5: 'cinque',
      6: 'sei',
      7: 'sette',
      8: 'otto',
      9: 'nove',
    };

    final currentSentence = '${numberNames[firstNumber]} ${numberNames[secondNumber]} ${numberNames[thirdNumber]} ${numberNames[fourthNumber]}';
    final currentSentenceAlternative = '$firstNumber$secondNumber$thirdNumber$fourthNumber';
  
    return speechResult == currentSentence || speechResult.replaceAll(' ', '') == currentSentenceAlternative;
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
      listenFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: false,
      ),
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

      pickRandomNumber();
      sentenceCaptured = false;
    }
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
        title: const Text('Riordina'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startListening,
        child: Stack(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Tocca lo schermo e ripeti in ordine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildQuadrant(1, firstNumber, deviceWidth),
                      _buildQuadrant(2, secondNumber, deviceWidth),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildQuadrant(3, thirdNumber, deviceWidth),
                      _buildQuadrant(4, fourthNumber, deviceWidth),
                    ],
                  ),
                ),
              ],
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
    );
  }

  Widget _buildQuadrant(int position, int number, double deviceDimension) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 3),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                '$position°',
                style: TextStyle(
                  fontSize: deviceDimension * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: deviceDimension * 0.17,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
