// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/search_meal_screen.dart

import 'package:flutter/material.dart';
import '../../services/nutrition_database.dart';
import 'meal_info_screen.dart';

class SearchMealScreen extends StatefulWidget {
  final String? preselectedMeal; // If opened from meal tracking

  const SearchMealScreen({Key? key, this.preselectedMeal}) : super(key: key);

  @override
  State<SearchMealScreen> createState() => _SearchMealScreenState();
}

class _SearchMealScreenState extends State<SearchMealScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  // --------------------------------------------------
  // SEARCH LOCAL JSON DATABASE
  // --------------------------------------------------
  void _search(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    final r = NutritionDatabase.search(text, limit: 50);

    setState(() {
      _results = r;
      _loading = false;
    });
  }

  // --------------------------------------------------
  // OPEN FOOD DETAILS — Pass ONLY FOOD JSON
  // --------------------------------------------------
  void _openFoodDetails(Map<String, dynamic> item) async {
    final Map<String, dynamic> info = {
      ...item, // full food json

      // pass preselected meal name (optional)
      "mealName": widget.preselectedMeal,

      // mode tells MealInfoScreen how it was opened
      "mode": widget.preselectedMeal == null
          ? "add_from_nutrition"
          : "add_from_tracking",
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealInfoScreen.fromSearch(info),
      ),
    );

    // If meal was added successfully, close search screen
    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  void initState() {
    super.initState();
    // NutritionDatabase.init() already called in main.dart
  }

  // --------------------------------------------------
  // UI SECTION (UNCHANGED)
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Search Food"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- Search Bar ----------------
            TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: "Search food…",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_loading) const LinearProgressIndicator(),

            // ---------------- Results List ----------------
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                child: Text(
                  "Search 'rice', 'milk', 'apple', 'dal'…",
                  style: TextStyle(color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final item = _results[i];

                  // calories from JSON (never saved to Firestore)
                  final calories =
                      item["nutrition_per_100g"]?["calories"] ?? 0;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _openFoodDetails(item),

                      title: Text(item["name"]),
                      subtitle: Text(
                        "$calories kcal per 100g",
                        style: const TextStyle(color: Colors.black54),
                      ),

                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _openFoodDetails(item),
                        child: const Text("Add"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
