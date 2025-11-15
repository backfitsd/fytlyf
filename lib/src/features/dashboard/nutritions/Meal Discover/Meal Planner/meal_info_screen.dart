// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/meal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/nutrition_repository.dart';

/// MealInfoScreen — saves minimal firestore payload:
/// { id, unit, amount, gram_weight, added_at }
class MealInfoScreen extends StatefulWidget {
  final Map<String, dynamic> info;
  final bool edit;
  final String? mealName;
  final String? mode;
  final String? date;
  final String? docId;

  MealInfoScreen.fromSearch(Map<String, dynamic> infoMap)
      : info = Map<String, dynamic>.from(infoMap),
        edit = false,
        mealName = infoMap["mealName"],
        mode = infoMap["mode"] ?? "add_from_nutrition",
        date = infoMap["date"],
        docId = null;

  MealInfoScreen.fromEdit(Map<String, dynamic> data)
      : info = Map<String, dynamic>.from(data["info"]),
        edit = true,
        mealName = data["mealName"],
        mode = "edit",
        date = data["date"],
        docId = data["docId"];

  @override
  State<MealInfoScreen> createState() => _MealInfoScreenState();
}

class _MealInfoScreenState extends State<MealInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // New model: amount + unit (rather than single integer quantity)
  double _amount = 1.0;
  String _selectedUnit = 'gram';

  // Keep legacy-compatible numeric display values for UI (calculated)
  int _displayKcal = 0;
  double _displayProt = 0.0;
  double _displayCarbs = 0.0;
  double _displayFat = 0.0;

  bool _loading = false;

  Map<String, dynamic> get base => widget.info;

  // Helper to parse numeric or string numbers
  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) {
      final cleaned = v.replaceAll(',', '');
      return num.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  String get name => base["name"] ?? "Food";
  String get description => base["description"] ?? "";
  int get baseWeightGram => (base['base_weight_gram'] is num) ? (base['base_weight_gram'] as num).toInt() : 100;

  /// measures map expected in JSON:
  /// e.g. { "gram":100, "ml":100, "cup":250, "tablespoon":15, ... }
  Map<String, dynamic> get measures {
    final m = base['measures'];
    if (m is Map<String, dynamic>) return m;
    if (m is Map) return Map<String, dynamic>.from(m);
    return {'gram': baseWeightGram};
  }

  Map<String, dynamic> get nutritionPer100 {
    final n = base['nutrition_per_100g'];
    if (n is Map<String, dynamic>) return n;
    if (n is Map) return Map<String, dynamic>.from(n);
    return {
      'calories': _toNum(base['calories']),
      'protein': _toNum(base['protein']),
      'carbs': _toNum(base['carbs']),
      'fat': _toNum(base['fat']),
    };
  }

  @override
  void initState() {
    super.initState();
    // If editing and doc has existing compact payload, prefill amount/unit
    _prefillFromInfoOrDoc();
    _recomputeNutrition();
  }

  void _prefillFromInfoOrDoc() {
    // If `info` is coming from Firestore edit payload, it may contain stored fields
    // like 'unit' and 'amount' (new format) or legacy nutrients.
    try {
      if (widget.edit) {
        // prefer explicit amount/unit if present in provided info map
        final unit = widget.info['unit'] as String?;
        final amt = widget.info['amount'];
        if (unit != null && amt != null) {
          _selectedUnit = unit;
          _amount = (amt is num) ? amt.toDouble() : double.tryParse(amt.toString()) ?? 1.0;
        }
      } else {
        // for new adds, if measures contains 'gram' we'll default select 'gram'
        if (measures.containsKey('gram')) {
          _selectedUnit = 'gram';
        } else {
          _selectedUnit = measures.keys.first;
        }
      }
    } catch (_) {}
  }

  double _unitToGramWeight(String unit, double amount) {
    // Convert chosen unit + amount to grams using measures map.
    // measures[unit] is the grams per 1 unit.
    final val = measures[unit];
    if (val == null) {
      // fallback to base weight gram * amount
      return baseWeightGram * amount;
    }
    // If the measure value is 0 (e.g., piece=0), then fallback to base_weight_gram for 1 piece
    final numVal = _toNum(val);
    if (numVal == 0) {
      return baseWeightGram * amount;
    }
    return numVal.toDouble() * amount;
  }

  void _recomputeNutrition() {
    final grams = _unitToGramWeight(_selectedUnit, _amount);
    final factor = grams / 100.0; // nutrition_per_100g basis

    final calories = _toNum(nutritionPer100['calories']).toDouble();
    final protein = _toNum(nutritionPer100['protein']).toDouble();
    final carbs = _toNum(nutritionPer100['carbs']).toDouble();
    final fat = _toNum(nutritionPer100['fat']).toDouble();

    setState(() {
      _displayKcal = (calories * factor).round();
      _displayProt = double.parse((protein * factor).toStringAsFixed(2));
      _displayCarbs = double.parse((carbs * factor).toStringAsFixed(2));
      _displayFat = double.parse((fat * factor).toStringAsFixed(2));
    });
  }

  // ---------------- SAVE MEAL ------------------
  Future<void> _saveMeal() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Not logged in")));
      return;
    }

    setState(() => _loading = true);

    final String today = DateTime.now().toIso8601String().split("T").first;
    final String date = widget.date ?? today;

    String? meal = widget.mealName;

    // If opening from Nutrition screen → ask the user to choose which meal
    if (!widget.edit && widget.mode == "add_from_nutrition") {
      meal = await _chooseMeal();
    }

    // If still null, prompt once more
    if (meal == null || meal.isEmpty) {
      meal = await _chooseMeal();
      if (meal == null || meal.isEmpty) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please choose a meal type")),
        );
        return;
      }
    }

    // If editing, make sure we have a docId to update
    if (widget.edit && (widget.docId == null || widget.docId!.isEmpty)) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot update item: missing document id")),
      );
      return;
    }

    // compute gram weight from chosen unit & amount
    final gramWeight = _unitToGramWeight(_selectedUnit, _amount);

    final itemId = base["id"]?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Minimal payload to store in Firestore (Option A)
    final data = <String, dynamic>{
      "id": itemId,
      "unit": _selectedUnit,
      "amount": _amount,
      "gram_weight": double.parse(gramWeight.toStringAsFixed(3)),
      "added_at": FieldValue.serverTimestamp(),
      // keep optional human-friendly fields (not required) — can be omitted, but helpful for UI quickly:
      "name": name,
      "serving": base['serving'] ?? '',
    };

    try {
      if (widget.edit) {
        // update existing
        await NutritionRepository.updateMealItem(
          uid,
          date,
          meal,
          widget.docId!,
          data,
        );
      } else {
        // add new
        await NutritionRepository.saveMealItem(
          meal,
          data,
          uid: uid,
          date: date,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, st) {
      // Detailed failure message for debugging & user feedback
      debugPrint("SAVE ERROR (MealInfoScreen): $e\n$st");
      String message = "Error saving meal";
      if (e.toString().contains("PERMISSION_DENIED") ||
          e.toString().toLowerCase().contains("permission")) {
        message = "Permission denied: check Firestore rules for users/$uid/meals";
      } else if (e.toString().toLowerCase().contains("not found")) {
        message = "Path not found or invalid. Check your Firestore structure.";
      } else {
        message = "Error saving meal: ${e.toString()}";
      }
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<String?> _chooseMeal() async {
    return await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text("Select Meal", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...[
              "Breakfast",
              "Morning Snack",
              "Lunch",
              "Evening Snack",
              "Dinner",
              "Others",
            ].map((m) => ListTile(title: Text(m), onTap: () => Navigator.pop(ctx, m))),
          ],
        ),
      ),
    );
  }

  // ---------------- UI BELOW (keeps original look, with small additions) ----------------
  @override
  Widget build(BuildContext context) {
    // Build list of available units from measures map (ensure 'gram' present)
    final availableUnits = <String>{}..addAll(measures.keys.map((k) => k.toString()));
    if (!availableUnits.contains('gram')) {
      availableUnits.add('gram'); // ensure gram exists
    }
    final unitList = availableUnits.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Meal Info", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageSection(),
              const SizedBox(height: 12),
              // ----- NEW: unit selector + amount input (keeps compact, matches UI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    // amount field
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: _amount.toString().replaceAll(RegExp(r'\.0+$'), ''),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v) ?? 0.0;
                          setState(() {
                            _amount = parsed <= 0 ? 0.0 : parsed;
                          });
                          _recomputeNutrition();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // unit dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            items: unitList.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u[0].toUpperCase() + u.substring(1)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _selectedUnit = v;
                              });
                              _recomputeNutrition();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _macroCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: GestureDetector(
          onTap: _saveMeal,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6D00), Color(0xFFFFA726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                widget.edit ? "SAVE" : "ADD",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageSection() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
          ),
          Positioned(left: 12, bottom: 12, child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _macroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Row(children: [
            _kcalCircle(),
            const SizedBox(width: 12),
            Expanded(child: _macroValues()),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nutrientCircle("Protein", "${_displayProt.toStringAsFixed(1)}g"),
            _nutrientCircle("Carbs", "${_displayCarbs.toStringAsFixed(1)}g"),
            _nutrientCircle("Fat", "${_displayFat.toStringAsFixed(1)}g"),
          ]),
        ],
      ),
    );
  }

  Widget _kcalCircle() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 8)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_outlined, color: Colors.orange, size: 22),
            const SizedBox(height: 4),
            Text("$_displayKcal Cal", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _macroValues() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text("$_displayKcal kcal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text("${_displayProt.toStringAsFixed(1)}g protein • ${_displayCarbs.toStringAsFixed(1)}g carbs • ${_displayFat.toStringAsFixed(1)}g fat",
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _nutrientCircle(String label, String value) {
    return Column(
      children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
            child: Center(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}
