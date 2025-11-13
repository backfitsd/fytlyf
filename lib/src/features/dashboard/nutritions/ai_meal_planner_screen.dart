// file: lib/src/features/dashboard/nutritions/ai_meal_planner_screen.dart
import 'package:flutter/material.dart';

class AiMealPlannerScreen extends StatefulWidget {
  const AiMealPlannerScreen({Key? key}) : super(key: key);

  @override
  State<AiMealPlannerScreen> createState() => _AiMealPlannerScreenState();
}

class _AiMealPlannerScreenState extends State<AiMealPlannerScreen> {
  // placeholder for user inputs
  String goal = 'Maintain weight';
  int calories = 2000;

  // pretend-generation result
  List<String> plan = [];

  void _generatePlan() {
    setState(() {
      plan = [
        'Mon: Oats + Fruit • 400 kcal',
        'Tue: Chicken salad • 550 kcal',
        'Wed: Protein bowl • 500 kcal',
        'Thu: Salmon + veg • 550 kcal',
        'Fri: Veg stir-fry • 400 kcal',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFF3D00), Color(0xFFFF6D00), Color(0xFFFFA726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Planner'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            const Text('Auto-generate a weekly meal plan based on your preferences.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: goal,
                      items: const [
                        DropdownMenuItem(value: 'Maintain weight', child: Text('Maintain weight')),
                        DropdownMenuItem(value: 'Lose weight', child: Text('Lose weight')),
                        DropdownMenuItem(value: 'Gain muscle', child: Text('Gain muscle')),
                      ],
                      onChanged: (v) => setState(() => goal = v ?? goal),
                      decoration: const InputDecoration(labelText: 'Goal'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: calories.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily calories'),
                      onChanged: (v) => calories = int.tryParse(v) ?? calories,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _generatePlan, child: const Text('Generate Plan')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (plan.isNotEmpty) ...[
              const Text('Suggested plan:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...plan.map((p) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(title: Text(p)),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
