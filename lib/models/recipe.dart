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
}