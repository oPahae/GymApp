import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/exercice.dart';

class DayProgram {
  final String day;
  final List<FoodModel> breakfastFoods;
  final List<FoodModel> lunchFoods;
  final List<FoodModel> dinnerFoods;
  final List<ExerciceModel> exercises;

  const DayProgram({
    required this.day,
    required this.breakfastFoods,
    required this.lunchFoods,
    required this.dinnerFoods,
    required this.exercises,
  });

  List<FoodModel> get allFoods => [...breakfastFoods, ...lunchFoods, ...dinnerFoods];
  double get totalCalories => allFoods.fold(0, (sum, f) => sum + f.calories);

  // TODO: ajouter fromJson/toJson quand FoodModel et ExerciceModel les auront
}