import 'package:test_hh/models/food.dart';

class RecipeModel {
  final String id;
  final String name;
  final String imageUrl;
  final double calories;
  final List<FoodModel> ingredients;
  bool isExpanded;

  RecipeModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.ingredients,
    this.isExpanded = false,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}