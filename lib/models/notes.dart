import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/bodyPart.dart';

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

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',

      exercices: json['exercices'] != null &&
              json['exercices'] is Map<String, dynamic>
          ? ExerciceModel.fromJson(json['exercices'])
          : ExerciceModel(
              id: '',
              name: '',
              description: '',
              image: '',
              video: '',
              type: ExerciceType.strength,
              notes: [],
              part: BodyPartModel(
                id: '',
                name: '',
                imageUrl: '',
                exercices: [],
              ),
            ),
    );
  }
}