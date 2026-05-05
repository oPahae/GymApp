import 'package:test_hh/models/coach.dart';

class Client {
  final int id;
  final String name;
  final String email; 
  final String password; 
  final String image;
  final DateTime birth;
  final double weight;
  final double height;
  final int frequency;
  final String goal;
  final double weightGoal;
  final DateTime createdAt;
  final int? coachID;
  final String gender;
  final Coach? coach;

  const Client({
    required this.id,
    required this.name,
    required this.email, // Ajouté
    required this.password, // Ajouté
    required this.image,
    required this.birth,
    required this.weight,
    required this.height,
    required this.frequency,
    required this.goal,
    required this.weightGoal,
    required this.createdAt,
    this.coachID,
    required this.gender,
    this.coach,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'] ?? '',
        image: json['image'] ?? '',
        birth: json['birth'] != null ? DateTime.parse(json['birth']) : DateTime.now(),
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        height: (json['height'] as num?)?.toDouble() ?? 0.0,
        frequency: json['frequency'] ?? 0,
        goal: json['goal'] ?? '',
        weightGoal: (json['weightGoal'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        coachID: json['coachID'], // Peut être null
        gender: json['gender'] ?? 'Male',
        coach: json['coach'] != null ? Coach.fromJson(json['coach']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email, // Ajouté
        'password': password, // Ajouté (à éviter d'envoyer en JSON)
        'image': image,
        'birth': birth.toIso8601String(),
        'weight': weight,
        'height': height,
        'frequency': frequency,
        'goal': goal,
        'weightGoal': weightGoal,
        'createdAt': createdAt.toIso8601String(),
        'coachID': coachID,
        'gender': gender,
        'coach': coach?.toJson(),
      };

  Client copyWith({
    int? id,
    String? name,
    String? email, // Ajouté
    String? password, // Ajouté
    String? image,
    DateTime? birth,
    double? weight,
    double? height,
    int? frequency,
    String? goal,
    double? weightGoal,
    DateTime? createdAt,
    int? coachID,
    String? gender,
    Coach? coach,
  }) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email, // Ajouté
        password: password ?? this.password, // Ajouté
        image: image ?? this.image,
        birth: birth ?? this.birth,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        frequency: frequency ?? this.frequency,
        goal: goal ?? this.goal,
        weightGoal: weightGoal ?? this.weightGoal,
        createdAt: createdAt ?? this.createdAt,
        coachID: coachID ?? this.coachID,
        gender: gender ?? this.gender,
        coach: coach ?? this.coach,
      );
}