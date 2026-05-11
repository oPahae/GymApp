import 'package:test_hh/models/client.dart';

class Coach {
  final int id;
  final String name;
  final DateTime? createdAt; // Rendu optionnel
  final String image;
  final List<Client> clients;
  final String? specialty;
  final String? bio;

  const Coach({
    required this.id,
    required this.name,
    this.createdAt, // Optionnel
    required this.image,
    List<Client>? clients,
    this.specialty,
    this.bio,
  }) : clients = clients ?? const [];

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null, // Optionnel
      image: json['image'] ?? '',
      clients: json['clients'] != null
          ? (json['clients'] as List)
              .map((c) => Client.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      specialty: json['specialty'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(), // Optionnel
      'image': image,
      'clients': clients.map((c) => c.toJson()).toList(),
      if (specialty != null) 'specialty': specialty, // Optionnel
      if (bio != null) 'bio': bio, // Optionnel
    };
  }

  Coach copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? image,
    List<Client>? clients,
    String? specialty,
    String? bio,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      image: image ?? this.image,
      clients: clients ?? this.clients,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
    );
  }
}