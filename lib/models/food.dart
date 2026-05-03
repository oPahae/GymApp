enum FoodType { solid, liquid, grains, unit }

class FoodModel {
  final String id;
  final String name;
  final String imageUrl;
  final double calories;
  final FoodType type;

  const FoodModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.type,
  });

  String get calLabel {
    switch (type) {
      case FoodType.liquid:
        return '${calories.toInt()} kcal/100ml';
      case FoodType.grains:
        return '${calories.toInt()} kcal/100g';
      case FoodType.unit:
        return '${calories.toInt()} kcal/unit';
      default:
        return '${calories.toInt()} kcal/100g';
    }
  }

  String get typeLabel {
    switch (type) {
      case FoodType.liquid:
        return 'LIQUID';
      case FoodType.grains:
        return 'SUPPL.';
      case FoodType.unit:
        return 'UNIT';
      default:
        return 'FOOD';
    }
  }
}