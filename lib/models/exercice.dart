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

  factory ExerciceModel.fromJson(Map<String, dynamic> json) {
    return ExerciceModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? json['imageUrl'] ?? '',
      video: json['video'] ?? '',

      type: _parseType(json['type']),

      notes: (json['notes'] as List<dynamic>?)
              ?.map((n) => NoteModel.fromJson(n))
              .toList() ??
          [],

      part: json['part'] != null && json['part'] is Map<String, dynamic>
          ? BodyPartModel.fromJson(json['part'])
          : BodyPartModel(
              id: (json['bodyPartID'] ?? '').toString(),
              name: json['bodyPartName'] ?? json['muscle'] ?? '',
              imageUrl: '',
              exercices: [],
            ),
    );
  }

  static ExerciceType _parseType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'cardio':
        return ExerciceType.cardio;
      case 'strength':
        return ExerciceType.strength;
      case 'flexibility':
        return ExerciceType.flexibility;
      case 'balance':
        return ExerciceType.balance;
      case 'liquid':
        return ExerciceType.liquid;
      case 'grains':
        return ExerciceType.grains;
      case 'unit':
        return ExerciceType.unit;
      default:
        return ExerciceType.cardio;
    }
  }

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
    }
  }
}