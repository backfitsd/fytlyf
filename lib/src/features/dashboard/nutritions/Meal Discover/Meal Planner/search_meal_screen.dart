import 'package:flutter/material.dart';
import '../../services/nutrition_database.dart';

class SearchMealScreen extends StatefulWidget {
  const SearchMealScreen({Key? key}) : super(key: key);

  @override
  State<SearchMealScreen> createState() => _SearchMealScreenState();
}

class _SearchMealScreenState extends State<SearchMealScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

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

  @override
  void initState() {
    super.initState();
    // NutritionDatabase.init is already called in main.dart
  }

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

            Expanded(
              child: _results.isEmpty
                  ? const Center(
                child:
                Text("Search 'rice', 'milk', 'chicken', 'maggi'…"),
              )
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final item = _results[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(item["name"]),
                      subtitle: Text(
                          "${item['serving']} • ${item['calories']} kcal"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context, item);
                        },
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
