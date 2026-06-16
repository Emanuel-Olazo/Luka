import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const LukaApp());
}

class LukaApp extends StatelessWidget {
  const LukaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luka App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
