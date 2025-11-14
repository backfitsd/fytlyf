import 'package:flutter/material.dart';

class MealInfoScreen extends StatefulWidget {
  final String item;
  const MealInfoScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<MealInfoScreen> createState() => _MealInfoScreenState();
}

class _MealInfoScreenState extends State<MealInfoScreen> {
  int _quantity = 1;
  String _measure = 'glass';

  // same app gradient used in NutritionScreen's EXPLORE button
  static const LinearGradient _appGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // base nutrition per measure (example values)
  final Map<String, Map<String, num>> _nutritionDatabase = {
    'milk': {"kcal": 150, "protein": 8, "carbs": 12, "fat": 8.5, "net_wt_ml": 200},
    'rice': {"kcal": 206, "protein": 4.2, "carbs": 45, "fat": 0.4, "net_wt_ml": 250},
    'egg': {"kcal": 78, "protein": 6.3, "carbs": 0.6, "fat": 5.3, "net_wt_ml": 50},
    'banana': {"kcal": 89, "protein": 1.1, "carbs": 23, "fat": 0.3, "net_wt_ml": 100},
    'chicken breast': {"kcal": 165, "protein": 31, "carbs": 0, "fat": 3.6, "net_wt_ml": 100},
    'oats': {"kcal": 389, "protein": 17, "carbs": 66, "fat": 7, "net_wt_ml": 50},
  };

  final List<String> _measures = ['glass', 'g', 'ml', 'pc'];

  String _normalizedKey(String raw) => raw.toLowerCase().split('-')[0].trim();

  Map<String, num> get _baseNutrition {
    final key = _normalizedKey(widget.item);
    return _nutritionDatabase[key] ?? _nutritionDatabase.values.first;
  }

  num get _kcal => _baseNutrition['kcal']! * _quantity;
  num get _protein => _baseNutrition['protein']! * _quantity;
  num get _carbs => _baseNutrition['carbs']! * _quantity;
  num get _fat => _baseNutrition['fat']! * _quantity;
  num get _netWt {
    final n = _baseNutrition['net_wt_ml'] ?? 0;
    return n * _quantity;
  }

  void _increase() => setState(() => _quantity++);
  void _decrease() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _onAdd() {
    Navigator.of(context).pop({
      'item': widget.item,
      'quantity': _quantity,
      'measure': _measure,
      'kcal': _kcal,
      'protein': _protein,
      'carbs': _carbs,
      'fat': _fat,
      'net_wt': _netWt,
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item.split('-').first.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
          const SizedBox(width: 8)
        ],
        title: const Text('Meal info', style: TextStyle(fontWeight: FontWeight.w700)),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // placeholder image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(Icons.photo, size: 48, color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // quantity & measure (switch to column on narrow widths)
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  return isNarrow
                      ? Column(
                    children: [
                      _quantityCard(),
                      const SizedBox(height: 8),
                      _measureCard(),
                    ],
                  )
                      : Row(
                    children: [
                      Expanded(child: _quantityCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _measureCard()),
                    ],
                  );
                }),

                const SizedBox(height: 14),

                // Macronutrient breakdown card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 8),
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_outlined, color: Colors.orangeAccent, size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_kcal.toInt()} Cal',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_kcal.toInt()} Cal',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Net wt: ${_netWt.toInt()} ${_measure == 'ml' || _measure == 'g' ? _measure : (_measure == 'pc' ? 'pc' : _measure)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _nutrientCircle('Protein', '${_protein.toStringAsFixed(0)}g'),
                          _nutrientCircle('Carbs', '${_carbs.toStringAsFixed(0)}g'),
                          _nutrientCircle('Fat', '${_fat.toStringAsFixed(1)}g'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // extra spacing so content isn't hidden behind bottom button
              ],
            ),
          ),
        ),
      ),

      // ADD button pinned to bottom — now using the app gradient
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: _onAdd,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: _appGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'ADD',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quantityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Text('Quantity', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _decrease,
            icon: const Icon(Icons.remove_circle_outline),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$_quantity',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: _increase,
            icon: const Icon(Icons.add_circle_outline),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _measureCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Text('Measure', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _measure,
              items: _measures
                  .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.w700))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _measure = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrientCircle(String label, String value) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
