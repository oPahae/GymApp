import 'package:test_hh/models/coach.dart';

class Client {
  final int id;
  final String name;
  final String email;
  final String? password; // Rendu optionnel
  final String image;
  final DateTime birth;
  final double weight;
  final double height;
  final int frequency;
  final String goal;
  final double weightGoal;
  final DateTime? createdAt; // Rendu optionnel
  final int? coachID;
  final String gender;
  final Coach? coach;

  const Client({
    required this.id,
    required this.name,
    required this.email,
    this.password, // Optionnel
    required this.image,
    required this.birth,
    required this.weight,
    required this.height,
    required this.frequency,
    required this.goal,
    required this.weightGoal,
    this.createdAt, // Optionnel
    this.coachID,
    required this.gender,
    this.coach,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'], // Peut être null
      image: json['image'] ?? '',
      birth: json['birth'] != null
          ? DateTime.tryParse(json['birth']) ?? DateTime.now()
          : DateTime.now(),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] ?? 0,
      goal: json['goal'] ?? '',
      weightGoal: (json['weightGoal'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null, // Optionnel
      coachID: json['coachID'],
      gender: json['gender'] ?? 'Male',
      coach: json['coach'] != null
          ? Coach.fromJson(json['coach'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (password != null) 'password': password, // Optionnel
      'image': image,
      'birth': birth.toIso8601String(),
      'weight': weight,
      'height': height,
      'frequency': frequency,
      'goal': goal,
      'weightGoal': weightGoal,
      if (createdAt != null)
        'createdAt': createdAt!.toIso8601String(), // Optionnel
      'coachID': coachID,
      'gender': gender,
      if (coach != null) 'coach': coach!.toJson(), // Optionnel
    };
  }

  Client copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
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
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
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

  int calculateAge() {
    final now = DateTime.now();
    int age = now.year - this.birth.year;
    if (now.month < this.birth.month ||
        (now.month == this.birth.month && now.day < this.birth.day)) {
      age--;
    }
    return age;
  }
}

extension ClientExtensions on Client {
  int get age => calculateAge();
  double get bmi => height > 0 ? weight / ((height / 100) * (height / 100)) : 0;
}