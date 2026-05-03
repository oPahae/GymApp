import 'package:test_hh/screens/home.dart';
import 'package:test_hh/screens/addFood.dart';
import 'package:test_hh/screens/foods.dart';
import 'package:test_hh/screens/clients.dart';
import 'package:flutter/material.dart';
import 'package:test_hh/screens/welcome.dart';
import 'package:test_hh/screens/programPage.dart';
import 'package:test_hh/screens/coachProgramPage.dart';


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
      home: CoachProgramPage(clientName: "Zineb",
      clientId: "123",),
    );
  }
}
