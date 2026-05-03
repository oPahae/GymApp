import 'package:test_hh/models/bodyPart.dart';
import 'package:test_hh/models/notes.dart';

enum ExerciceType {
  cardio,
  strength,
  flexibility,
  balance,
  liquid,
  grains,
  unit,
}

class ExerciceModel {
  final String id;
  final String name;
  final BodyPartModel part;
  final String image;
  final String video;
  final String description;
  final ExerciceType type;
  final List<NoteModel> notes;
  const ExerciceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.video,
    required this.part,
    required this.type,
    required this.notes,
  });

  String get typeLabel {
    switch (type) {
      case ExerciceType.cardio:
        return 'CARDIO';
      case ExerciceType.strength:
        return 'STRENGTH';
      case ExerciceType.flexibility:
        return 'FLEXIBILITY';
      case ExerciceType.balance:
        return 'BALANCE';
      case ExerciceType.liquid:
        return 'LIQUID';
      case ExerciceType.grains:
        return 'SUPPL.';
      case ExerciceType.unit:
        return 'UNIT';
      default:
        return 'EXERCICE';
    }
  }
}
