// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/meal_info_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/nutrition_repository.dart';

class MealInfoScreen extends StatefulWidget {
  final Map<String, dynamic> info;
  final bool edit;
  final String? mealName;
  final String? mode;
  final String? date;
  final String? docId;

  /// OPENED FROM SEARCH SCREEN (ADD ONLY)
  MealInfoScreen.fromSearch(Map<String, dynamic> infoMap)
      : info = Map<String, dynamic>.from(infoMap),
        edit = false,
        mealName = infoMap["mealName"],
        mode = infoMap["mode"] ?? "add_from_nutrition",
        date = infoMap["date"],
        docId = null;

  /// OPENED FROM MEAL TRACKING (EDIT MODE)
  MealInfoScreen.fromEdit(Map<String, dynamic> data)
      : info = Map<String, dynamic>.from(data["info"]),
        edit = true,
        mealName = data["mealName"],
        mode = "edit",
        date = data["date"],
        docId = data["docId"];

  @override
  State<MealInfoScreen> createState() => _MealInfoScreenState();
}

class _MealInfoScreenState extends State<MealInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Map<String, dynamic> food;
  String selectedUnit = "gram";
  int amount = 1;

  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  double weightGrams = 0;

  @override
  void initState() {
    super.initState();
    food = widget.info;

    _initializeDefaultUnit();
    _recalculate();
  }

  /// Set initial unit intelligently
  void _initializeDefaultUnit() {
    final measures = food["measures"];
    if (measures is Map && measures.isNotEmpty) {
      selectedUnit = measures.keys.first;
    }
    if (widget.edit) {
      selectedUnit = food["unit"] ?? selectedUnit;
      amount = food["amount"] ?? 1;
    }
  }

  /// Recalculate nutrition using repository logic
  void _recalculate() {
    final calc = NutritionRepository.calculateNutritionFromFood(
      foodJson: food,
      unit: selectedUnit,
      amount: amount,
    );

    setState(() {
      weightGrams = calc["weight_grams"];
      calories = calc["calories"];
      protein = calc["protein"];
      carbs = calc["carbs"];
      fat = calc["fat"];
    });
  }

  /// Ask user to choose meal type when opened from NutritionScreen
  Future<String?> _chooseMeal() async {
    final meals = [
      "Breakfast",
      "Morning Snack",
      "Lunch",
      "Evening Snack",
      "Dinner",
      "Others"
    ];

    return await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text("Choose meal type")),
              ...meals.map((m) {
                return ListTile(
                  title: Text(m),
                  onTap: () => Navigator.pop(ctx, m),
                );
              })
            ],
          ),
        );
      },
    );
  }

  /// SAVE or UPDATE the meal item
  Future<void> _save() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final String today = DateTime.now().toIso8601String().split("T").first;
    final date = widget.date ?? today;

    String? meal = widget.mealName;

    // ASK MEAL TYPE if opened from NutritionScreen
    if (!widget.edit && widget.mode == "add_from_nutrition") {
      meal ??= await _chooseMeal();
    }

    if (meal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please choose a meal type")),
      );
      return;
    }

    if (widget.edit) {
      /// EDIT MODE
      final success = await NutritionRepository.updateMealItem(
        uid: uid,
        date: date,
        mealName: meal,
        docId: widget.docId!,
        foodJson: food,
        unit: selectedUnit,
        amount: amount,
      );

      if (success) Navigator.pop(context, true);
    } else {
      /// ADD MODE
      await NutritionRepository.saveMealItem(
        uid: uid,
        date: date,
        mealName: meal,
        foodJson: food,
        unit: selectedUnit,
        amount: amount,
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measures = food["measures"] is Map ? (food["measures"] as Map) : {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(widget.edit ? "Edit Meal" : "Add Meal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FOOD NAME
            Text(
              food["name"] ?? "Food",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // UNIT SELECTOR
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Choose Unit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: measures.keys.map<Widget>((unit) {
                return ChoiceChip(
                  label: Text(unit),
                  selected: selectedUnit == unit,
                  onSelected: (_) {
                    selectedUnit = unit;
                    _recalculate();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // AMOUNT SELECTOR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Amount",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: amount > 1
                          ? () {
                        amount--;
                        _recalculate();
                      }
                          : null,
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Text(
                      "$amount",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () {
                        amount++;
                        _recalculate();
                      },
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // NUTRITION PREVIEW CARD
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "${weightGrams.toStringAsFixed(1)} g total",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _nutCell("Calories", "${calories.toStringAsFixed(0)} kcal"),
                        _nutCell("Protein", "${protein.toStringAsFixed(1)} g"),
                        _nutCell("Carbs", "${carbs.toStringAsFixed(1)} g"),
                        _nutCell("Fat", "${fat.toStringAsFixed(1)} g"),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const Spacer(),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: Text(
                  widget.edit ? "Update Meal" : "Add Meal",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _nutCell(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }
}
