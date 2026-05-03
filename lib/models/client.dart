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
  final int coachId;
 
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
    required this.coachId,
  });
 
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
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
      coachId: json['coachID'],
    );
  }
 
  Map<String, dynamic> toJson() {
    return {
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
      'coachID': coachId,
    };
  }
}