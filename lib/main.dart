import 'package:flutter/material.dart';

void main() {
  runApp(
    GymApp()
  );
}

class GymApp extends StatelessWidget {
  const GymApp({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Text("Hi"),
    );
  }
}