// main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/game_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farming in Purria',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const GameScreen(),
    );
  }
}