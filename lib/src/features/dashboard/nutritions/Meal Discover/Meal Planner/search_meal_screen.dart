// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/search_meal_screen.dart
import 'package:flutter/material.dart';
import 'meal_info_screen.dart'; // <-- adjust this import if your meal info file is named or located differently

class SearchMealScreen extends StatefulWidget {
  const SearchMealScreen({Key? key}) : super(key: key);

  @override
  State<SearchMealScreen> createState() => _SearchMealScreenState();
}

class _SearchMealScreenState extends State<SearchMealScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _all = [
    'Rice - 250 g',
    'Milk - 250 ml',
    'Egg - 1 pc',
    'Banana - 100 g',
    'Chicken Breast - 100 g',
    'Oats - 50 g',
  ];
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_all);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = _all.where((s) => s.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSelect(String item) {
    // If you want to return the selected item to the previous screen:
    Navigator.pop(context, item);
    // Or perform other behaviour like opening an edit dialog to set qty/kcal.
  }

  void _openMealInfo(String item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealInfoScreen(item: item)),
    ).then((result) {
      // result will be the map returned from MealInfoScreen._onAdd (if any)
      if (result != null) {
        // handle returned data if needed
        // e.g. Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search meal', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search food or brand',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // results
            Expanded(
              child: _filtered.isEmpty
                  ? Center(child: Text('No results', style: TextStyle(color: Colors.black54)))
                  : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = _filtered[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _onSelect(item), // row tap still returns selection
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.food_bank, size: 20, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w700))),
                            // Replaced chevron with a tappable plus icon
                            IconButton(
                              onPressed: () => _openMealInfo(item),
                              icon: const Icon(Icons.add_circle, color: Colors.deepOrangeAccent),
                              tooltip: 'Add / View details',
                            ),
                          ],
                        ),
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
