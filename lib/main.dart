import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_Sonno_Beta/screens/alarms_screen.dart';
import 'package:i_Sonno_Beta/utils/logging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  setupLogging(showDebugLogs: true);

  await Alarm.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 10, 10, 10),
        primaryColor: const Color.fromARGB(255, 0, 29, 61),
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 0, 61, 117),
          secondary: Color.fromARGB(255, 0, 61, 117),
          surface: Color.fromARGB(255, 0, 61, 117),
          onPrimary: Color.fromARGB(206, 255, 255, 255),
          onSecondary: Color.fromARGB(206, 255, 255, 255),
          onSurface: Color.fromARGB(255, 230, 230, 230),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 0, 29, 61),
          foregroundColor: Color.fromARGB(206, 255, 255, 255),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 29, 61),
            foregroundColor: const Color.fromARGB(206, 255, 255, 255),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        cardTheme: const CardTheme(
          color: Color.fromARGB(255, 0, 45, 87),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color.fromARGB(206, 255, 255, 255)),
          bodyMedium: TextStyle(color: Color.fromARGB(206, 255, 255, 255)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.green; // thumb when ON
            }
            return const Color.fromARGB(255, 0, 8, 20); // thumb when OFF
          }),
          trackColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color.fromARGB(255, 0, 53, 102); // track when ON
            }
            return const Color.fromARGB(255, 0, 53, 102); // track when OFF
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.green; // outline when ON
            }
            return const Color.fromARGB(255, 0, 8, 20); // outline when OFF
          }),
        ),
      ),
      home: const AlarmsScreen(),
    ),
  );
}
