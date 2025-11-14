// file: lib/src/features/dashboard/nutritions/recipe_screen.dart
import 'package:flutter/material.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({Key? key}) : super(key: key);

  final List<String> sampleRecipes = const [
    'Oats Pancake',
    'Grilled Veg Sandwich',
    'Salmon with Quinoa',
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFF3D00), Color(0xFFFF6D00), Color(0xFFFFA726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: sampleRecipes.length,
          itemBuilder: (context, index) {
            final name = sampleRecipes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(name[0])),
                title: Text(name),
                subtitle: const Text('Tap to view recipe'),
                onTap: () {
                  // simple recipe details bottom sheet (placeholder)
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(16),
                      height: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text('Ingredients:\n- ...\n\nSteps:\n1. ...\n2. ...'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
