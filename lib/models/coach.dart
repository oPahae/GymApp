class Coach {
  final int id;
  final String name;
  final DateTime createdAt;
  final String image;

  const Coach({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.image,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'image': image,
    };
  }
}