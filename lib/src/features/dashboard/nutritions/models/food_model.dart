// file: lib/src/features/dashboard/nutritions/models/food_model.dart

class FoodModel {
  final int id;
  final String name;
  final String description;
  final double baseWeightGram;

  final Map<String, double> measures;
  final Map<String, double> per100g;

  FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.baseWeightGram,
    required this.measures,
    required this.per100g,
  });

  /// Parse JSON item from nutrition_100_foods.json
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      baseWeightGram: (json["base_weight_gram"] ?? 100).toDouble(),
      measures: (json["measures"] ?? {})
          .map<String, double>((key, value) => MapEntry(key, value.toDouble())),
      per100g: (json["nutrition_per_100g"] ?? {})
          .map<String, double>((key, value) => MapEntry(key, value.toDouble())),
    );
  }

  /// Convert unit → gram
  double convertToGram({
    required double quantity,
    required String unit,
  }) {
    final gramValue = measures[unit] ?? 0;
    return (gramValue * quantity);
  }

  /// Return nutrition based on gram weight
  Map<String, double> getNutritionForGram(double gram) {
    double factor = gram / 100.0;

    return {
      "calories": per100g["calories"]! * factor,
      "protein": per100g["protein"]! * factor,
      "carbs": per100g["carbs"]! * factor,
      "fat": per100g["fat"]! * factor,
    };
  }
}
