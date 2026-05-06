import 'package:test_hh/models/exercice.dart';

class BodyPartModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<ExerciceModel> exercices;

  const BodyPartModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.exercices,
  });

  factory BodyPartModel.fromJson(Map<String, dynamic> json) {
    return BodyPartModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      exercices: (json['exercices'] as List?)
              ?.map((e) => ExerciceModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
