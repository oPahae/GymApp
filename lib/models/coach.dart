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
    List<Client>? clients,  // ← optionnel dans le constructeur
    this.specialty,
    this.bio,
  }) : clients = clients ?? const []; // ← valeur par défaut

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      image: json['image'],
      clients: json['clients'] != null
          ? (json['clients'] as List)
              .map((clientJson) => Client.fromJson(clientJson))
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
      'createdAt': createdAt.toIso8601String(),
      'image': image,
      'clients': clients.map((client) => client.toJson()).toList(),
      'specialty': specialty,
      'bio': bio,
    };
  }
}