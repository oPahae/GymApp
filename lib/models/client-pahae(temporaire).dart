enum Gender { male, female }

class ClientModel {
  final String id;
  final String name;
  final String imageUrl;
  final Gender gender;
  final DateTime birthDate;

  const ClientModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.gender,
    required this.birthDate,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}