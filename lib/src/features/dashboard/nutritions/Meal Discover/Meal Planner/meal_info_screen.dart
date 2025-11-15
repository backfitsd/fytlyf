import 'package:flutter/material.dart';

class MealInfoScreen extends StatelessWidget {
  final Map<String, dynamic> info;

  const MealInfoScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(info["name"]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.05),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Serving: ${info['serving']}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text("Calories: ${info['calories']} kcal",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Protein: ${info['protein']} g"),
              Text("Carbs: ${info['carbs']} g"),
              Text("Fat: ${info['fat']} g"),
            ],
          ),
        ),
      ),
    );
  }
}
