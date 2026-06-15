import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Luka App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Luka - Starter App'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: Text(
            '¡Hola Luka!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    )
  );
}
