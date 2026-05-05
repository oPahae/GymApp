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

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '', // ✅ FIX
      calories: (json['calories'] ?? 0).toDouble(),
      type: _parseType(json['type']),
    );
  }

  static FoodType _parseType(String? type) {
    switch (type) {
      case 'liquid':
        return FoodType.liquid;
      case 'grains':
        return FoodType.grains;
      case 'unit':
        return FoodType.unit;
      default:
        return FoodType.solid;
    }
  }

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