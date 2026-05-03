import 'package:test_hh/models/food.dart';

class RecipeIngredientModel {
  final FoodModel food;
  double quantity; // grams / ml / units depending on type

  RecipeIngredientModel({required this.food, this.quantity = 100});

  double get contributedCalories {
    switch (food.type) {
      case FoodType.unit:
        return food.calories * quantity;
      default:
        return food.calories * quantity / 100;
    }
  }

  String get quantityLabel {
    switch (food.type) {
      case FoodType.liquid:
        return '${quantity.toInt()} ml';
      case FoodType.unit:
        return '${quantity.toInt()}×';
      default:
        return '${quantity.toInt()} g';
    }
  }
}