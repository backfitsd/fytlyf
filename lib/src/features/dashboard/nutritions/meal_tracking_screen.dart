// file: lib/src/features/dashboard/nutritions/meal_tracking_screen.dart
import 'package:flutter/material.dart';

class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({Key? key}) : super(key: key);

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen> {
  // Simple in-memory mock state for now
  Map<String, List<MealItem>> meals = {
    'Breakfast': [],
    'Lunch': [],
    'Snack': [],
    'Dinner': [],
  };

  void _addDummyMeal(String section) {
    setState(() {
      meals[section]!.add(
        MealItem(
          name: 'Sample ${meals[section]!.length + 1}',
          kcal: 120 + (meals[section]!.length * 10),
          time: TimeOfDay.now().format(context),
        ),
      );
    });
  }

  void _openMealDetail(MealItem item) {
    // For now show detail as simple dialog. Replace with a dedicated page if you want.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Text('Calories: ${item.kcal}\nTime: ${item.time}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [
        Color(0xFFFF3D00),
        Color(0xFFFF6D00),
        Color(0xFFFFA726),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        title: const Text('Meal Tracking'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Track meals for the day. Tap a section to add or view items.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // Build sections
            ...meals.keys.map((section) {
              final items = meals[section]!;
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(section, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Colors.black12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _addDummyMeal(section),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('No items yet', style: TextStyle(color: Colors.black45)),
                        )
                      else
                        Column(
                          children: items.map((it) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => _openMealDetail(it),
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade100,
                                child: const Icon(Icons.restaurant, color: Colors.black54),
                              ),
                              title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${it.kcal} kcal • ${it.time}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    items.remove(it);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class MealItem {
  final String name;
  final int kcal;
  final String time;

  MealItem({required this.name, required this.kcal, required this.time});
}
