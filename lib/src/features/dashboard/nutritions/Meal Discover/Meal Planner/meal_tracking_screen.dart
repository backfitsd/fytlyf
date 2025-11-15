// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/meal_tracking_screen.dart
// FIXED VERSION — All num→int errors solved, full working, ready to paste.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../nutritions/nutrition_screen.dart';
import 'search_meal_screen.dart';

class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({Key? key}) : super(key: key);

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final String todayKey;

  final List<String> mealSections = [
    "Breakfast",
    "Morning Snack",
    "Lunch",
    "Evening Snack",
    "Dinner",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    todayKey = "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  // ----------------------------------------------------------------
  // DELETE ITEM
  // ----------------------------------------------------------------
  Future<void> deleteItem(String mealName, String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection("users")
        .doc(uid)
        .collection("meals")
        .doc(todayKey)
        .collection(mealName)
        .doc(docId)
        .delete();
  }

  // ----------------------------------------------------------------
  // ADD MEAL FROM SEARCH SCREEN
  // ----------------------------------------------------------------
  Future<void> addMeal(String mealSection) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMealScreen(
          preSelectedMeal: mealSection,
        ),
      ),
    );
    if (res != null) {
      setState(() {});
    }
  }

  // ----------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Meal Planner"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
            color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: mealSections.length,
        padding: const EdgeInsets.only(bottom: 22),
        itemBuilder: (context, index) {
          final mealName = mealSections[index];
          return _mealSectionCard(mealName, size);
        },
      ),
    );
  }

  // ----------------------------------------------------------------
  // MEAL SECTION CARD
  // ----------------------------------------------------------------
  Widget _mealSectionCard(String mealName, Size size) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const SizedBox();
    }

    final ref = _db
        .collection("users")
        .doc(uid)
        .collection("meals")
        .doc(todayKey)
        .collection(mealName)
        .orderBy("timestamp", descending: true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
      child: Material(
        elevation: 4,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: ref.snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------ HEADER ------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mealName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => addMeal(mealName),
                          child: Row(
                            children: const [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "Add",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (docs.isEmpty)
                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Text(
                        "No items added",
                        style:
                        TextStyle(color: Colors.black45, fontSize: 14.5),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _mealItemTile(
                            mealName, docs[i].id, data, size);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // MEAL ITEM TILE
  // ----------------------------------------------------------------
  Widget _mealItemTile(
      String mealName, String docId, Map<String, dynamic> data, Size size) {
    final foodId = data["food_id"];
    final unit = data["unit"] ?? "";
    final amount = data["amount"] ?? 1;
    final weight = data["weight_grams"] ?? 0;

    final food = NutritionDatabase.foodById(foodId);

    // If food not found
    if (food == null) {
      return ListTile(
        title: const Text("Unknown Food"),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => deleteItem(mealName, docId),
        ),
      );
    }

    // NUTRITION PER 100g
    final nut = food["nutrition_per_100g"];

    // ❗❗ FIXED — ALL VALUES SAFELY CONVERTED
    final calories = ((nut["calories"] ?? 0) as num).toDouble();
    final protein = ((nut["protein"] ?? 0) as num).toDouble();
    final carbs = ((nut["carbs"] ?? 0) as num).toDouble();
    final fat = ((nut["fat"] ?? 0) as num).toDouble();

    // Final values based on portion
    final double multiplier = weight / 100.0;

    final int finalCal = (calories * multiplier).toInt();
    final double finalProt = protein * multiplier;
    final double finalCarb = carbs * multiplier;
    final double finalFat = fat * multiplier;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12, width: 0.4),
        ),
      ),
      child: Row(
        children: [
          // ---------------- MAIN INFO ----------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food["name"],
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  "$amount × $unit  •  ${weight}g",
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  "$finalCal Cal • P ${finalProt.toStringAsFixed(1)}g  C ${finalCarb.toStringAsFixed(1)}g  F ${finalFat.toStringAsFixed(1)}g",
                  style: const TextStyle(
                      fontSize: 12.5, color: Colors.black87),
                ),
              ],
            ),
          ),

          // ---------------- DELETE BUTTON ----------------
          IconButton(
            icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
            onPressed: () => deleteItem(mealName, docId),
          )
        ],
      ),
    );
  }
}
