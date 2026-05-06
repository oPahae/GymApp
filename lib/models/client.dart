import 'package:test_hh/models/coach.dart';

class Client {
  final int id;
  final String name;
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
    required this.image,
    required this.birth,
    required this.weight,
    required this.height,
    required this.frequency,
    required this.goal,
    required this.weightGoal,
    required this.createdAt,
    required this.coachID,
    required this.gender,
    this.coach, // Initialisation optionnelle
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'],
        name: json['name'],
        image: json['image'],
        birth: DateTime.parse(json['birth']),
        weight: (json['weight'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        frequency: json['frequency'],
        goal: json['goal'],
        weightGoal: (json['weightGoal'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
        coachID: json['coachID'],
        gender: json['gender'] ?? 'Male',
        coach: json['coach'] != null ? Coach.fromJson(json['coach']) : null, // Parsing du coach
      );

  get age => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
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
        'coach': coach?.toJson(), // Sérialisation du coach
      };

  Client copyWith({
    int? id,
    String? name,
    String? image,
    DateTime? birth,
    double? weight,
    double? height,
    int? frequency,
    String? goal,
    double? weightGoal,
    DateTime? createdAt,
    int? coachId,
    String? gender,
    Coach? coach, // Ajout dans copyWith
  }) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
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
        coach: coach ?? this.coach, // Mise à jour du coach
      );
}