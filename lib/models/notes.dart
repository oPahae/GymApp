import 'package:test_hh/models/exercice.dart';

class NoteModel {
  final String id;
  final String text;
  final String imageUrl;
  final ExerciceModel exercices;

  const NoteModel({
    required this.id,
    required this.text,
    required this.imageUrl,
    required this.exercices,
  });
}
