import 'package:test_hh/models/client.dart';

class Coach {
  final int id;
  final String name;
  final DateTime createdAt;
  final String image;
  final List<Client> clients;
  final String? specialty;
  final String? bio;

  const Coach({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.image,
    List<Client>? clients,
    this.specialty,
    this.bio,
  }) : clients = clients ?? const [];

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'image': image,
        'clients': clients.map((c) => c.toJson()).toList(),
        'specialty': specialty,
        'bio': bio,
      };

  Coach copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? image,
    List<Client>? clients,
    String? specialty,
    String? bio,
  }) =>
      Coach(
        id:        id        ?? this.id,
        name:      name      ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        image:     image     ?? this.image,
        clients:   clients   ?? this.clients,
        specialty: specialty ?? this.specialty,
        bio:       bio       ?? this.bio,
      );
}