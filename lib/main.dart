import 'package:flutter/material.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';
import 'package:test_hh/screens/clients.dart';
import 'package:test_hh/screens/profile.dart';

void main() {
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  // Données de test pour un coach avec des clients
  static final Coach testCoach = Coach(
    id: 1,
    name: 'John Smith',
    createdAt: DateTime(2022, 1, 15),
    image: 'https://example.com/coach_image.jpg',
    specialty: 'Strength & Conditioning',
    bio: 'Passionate coach helping athletes reach their peak.',
    clients: [
      // Client 1
      Client(
        id: 1,
        name: 'Alex Johnson',
        image: 'https://example.com/client1.jpg',
        birth: DateTime(1998, 4, 12),
        weight: 78.5,
        height: 181,
        frequency: 2,
        goal: 'Lose Weight',
        weightGoal: 72.0,
        createdAt: DateTime(2023, 5, 10),
        coachID: 1,
        gender: 'Male',
        coach: null,
      ),
      // Client 2
      Client(
        id: 2,
        name: 'Emma Wilson',
        image: 'https://example.com/client2.jpg',
        birth: DateTime(1995, 8, 22),
        weight: 65.0,
        height: 165,
        frequency: 3,
        goal: 'Build Muscle',
        weightGoal: 70.0,
        createdAt: DateTime(2023, 6, 15),
        coachID: 1,
        gender: 'Female',
        coach: null,
      ),
      // Client 3
      Client(
        id: 3,
        name: 'Michael Brown',
        image: 'https://example.com/client3.jpg',
        birth: DateTime(1990, 11, 5),
        weight: 90.0,
        height: 185,
        frequency: 4,
        goal: 'Boost Endurance',
        weightGoal: 85.0,
        createdAt: DateTime(2023, 7, 20),
        coachID: 1,
        gender: 'Male',
        coach: null,
      ),
    ],
  );

  // Données de test pour un client avec un coach
  static final Client testClientWithCoach = Client(
    id: 1,
    name: 'Alex Johnson',
    image: 'https://example.com/client1.jpg',
    birth: DateTime(1998, 4, 12),
    weight: 78.5,
    height: 181,
    frequency: 2,
    goal: 'Lose Weight',
    weightGoal: 72.0,
    createdAt: DateTime(2023, 5, 10),
    coachID: 1,
    gender: 'Male',
    coach: Coach(
      id: 1,
      name: 'John Smith',
      createdAt: DateTime(2022, 1, 15),
      image: 'https://example.com/coach_image.jpg',
      specialty: 'Strength & Conditioning',
      bio: 'Passionate coach helping athletes reach their peak.',
      clients: [], // Non utilisé ici, mais peut être rempli si nécessaire
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      // Pour tester le profil d'un coach avec ses clients
      home: ClientsScreen(
        // coach: testCoach,
        // coachClients: testCoach.clients, // Passe explicitement la liste des clients
      ),
      // Pour tester le profil d'un client avec son coach
      //home: ProfileScreen(client: testClientWithCoach),
    );
  }
}