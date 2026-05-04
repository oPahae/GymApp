import 'package:flutter/material.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';
import 'package:test_hh/screens/clients.dart';
import 'package:test_hh/screens/home.dart';
import 'package:test_hh/screens/profileClient.dart';
import 'package:test_hh/screens/welcome.dart';
import 'package:test_hh/screens/client.dart';
void main() {
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: SplashScreen(),
    );
  }
}