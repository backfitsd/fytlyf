// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/search_meal_screen.dart
// Search screen that returns full food JSON to MealInfoScreen.
// Accepts optional preselected meal as `preselectedMeal`.

import 'package:flutter/material.dart';
import '../../services/nutrition_database.dart';
import 'meal_info_screen.dart';

class SearchMealScreen extends StatefulWidget {
  final String? preselectedMeal; // note lowercase 'preselectedMeal'

  const SearchMealScreen({super.key, this.preselectedMeal});

  @override
  State<SearchMealScreen> createState() => _SearchMealScreenState();
}

class _SearchMealScreenState extends State<SearchMealScreen> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  void _search(String q) async {
    final text = q.trim();
    if (text.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final res = await NutritionDatabase.search(text, limit: 60);
    if (mounted) {
      setState(() {
        _results = res;
        _loading = false;
      });
    }
  }

  void _openFood(Map<String, dynamic> food) async {
    // attach mealName + mode
    final info = {
      ...food,
      'mealName': widget.preselectedMeal,
      'mode': widget.preselectedMeal == null ? 'add_from_nutrition' : 'add_from_tracking',
      'date': null,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealInfoScreen.fromSearch(info)),
    );

    if (mounted && result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Search Food"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: "Search food…",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text("Try searching 'rice', 'milk', 'apple'"))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final food = _results[i];
                final nut = food['nutrition_per_100g'] ?? {};
                final cal = (nut['calories'] ?? 0).toString();
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    onTap: () => _openFood(food),
                    title: Text(food['name'] ?? 'Food'),
                    subtitle: Text("$cal kcal per 100g"),
                    trailing: ElevatedButton(
                      onPressed: () => _openFood(food),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("Add"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
