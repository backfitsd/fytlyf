// file: lib/src/features/dashboard/nutritions/recommend_screen.dart
import 'package:flutter/material.dart';

class RecommendScreen extends StatelessWidget {
  const RecommendScreen({Key? key}) : super(key: key);

  // Example static recommendations — replace with real logic later
  final List<Map<String, String>> _samples = const [
    {'title': 'Greek Yogurt + Berries', 'desc': 'High protein breakfast'},
    {'title': 'Grilled Chicken Salad', 'desc': 'Low carb lunch'},
    {'title': 'Quinoa Bowl', 'desc': 'Balanced macros'},
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
        title: const Text('Recommend for you'),
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
            const SizedBox(height: 8),
            const Text('Personalized suggestions based on goals and preferences.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ..._samples.map((s) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: const Icon(Icons.fastfood)),
                  title: Text(s['title']!),
                  subtitle: Text(s['desc']!),
                  trailing: ElevatedButton(onPressed: () {}, child: const Text('Add')),
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
