import 'package:test_hh/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:test_hh/screens/coaches.dart';
import 'package:test_hh/screens/invites.dart';

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
      home: InvitesPage(),
    );
  }
}