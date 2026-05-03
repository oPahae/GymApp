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
}
