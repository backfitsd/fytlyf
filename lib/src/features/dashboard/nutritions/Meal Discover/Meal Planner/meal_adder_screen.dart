// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/meal_adder_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math';

// import the search screen (same folder)
import 'search_meal_screen.dart';

class MealAdderScreen extends StatefulWidget {
  final String mealName;
  const MealAdderScreen({Key? key, required this.mealName}) : super(key: key);

  @override
  State<MealAdderScreen> createState() => _MealAdderScreenState();
}

class _FoodItem {
  String name;
  String qtyLabel; // e.g. "250 g" or "250 ml"
  int kcal;
  _FoodItem({required this.name, required this.qtyLabel, required this.kcal});
}

class _MealAdderScreenState extends State<MealAdderScreen> {
  final List<_FoodItem> _items = [
    _FoodItem(name: 'Rice', qtyLabel: '250 g', kcal: 200),
    _FoodItem(name: 'Milk', qtyLabel: '250 ml', kcal: 150),
  ];

  void _showAddEditDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final _nameCtrl = TextEditingController(text: isEdit ? _items[editIndex!].name : '');
    final _qtyCtrl = TextEditingController(text: isEdit ? _items[editIndex!].qtyLabel : '');
    final _kcalCtrl = TextEditingController(text: isEdit ? _items[editIndex!].kcal.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit item' : 'Add item to ${widget.mealName}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Food item'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity (e.g. 250 g, 1 cup)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _kcalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final qty = _qtyCtrl.text.trim();
                final kcal = int.tryParse(_kcalCtrl.text.trim()) ?? 0;
                if (name.isEmpty || qty.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name and qty')));
                  return;
                }
                setState(() {
                  if (isEdit) {
                    _items[editIndex!] = _FoodItem(name: name, qtyLabel: qty, kcal: kcal);
                  } else {
                    _items.insert(0, _FoodItem(name: name, qtyLabel: qty, kcal: kcal));
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _showItemMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEditDialog(editIndex: index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _items.removeAt(index));
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Today, ${months[now.month - 1]} ${now.day}';
  }

  Widget _summaryCard(BuildContext ctx) {
    final totalKcal = _items.fold<int>(0, (p, e) => p + e.kcal);
    final prot = 10;
    final carbs = 70;
    final fat = 10;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 86,
            width: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(86,86),
                  painter: _SolidRingPainterMock(progress: min(1.0, totalKcal / 800), ringWidth: 9, ringColor: const Color(0xFFFFA726), baseColor: const Color(0xFFE8F2FF)),
                ),
                Icon(Icons.fastfood, size: 36, color: Colors.black87),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalKcal of 675 Cal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _macroRow(Iconsax.cup, 'Protein', '$prot/30 g'),
                    const SizedBox(height: 6),
                    _macroRow(Iconsax.ranking, 'Carbs', '$carbs/100 g'),
                    const SizedBox(height: 6),
                    _macroRow(Iconsax.coffee, 'Fat', '$fat/30 g'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          height: 26,
          width: 26,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _itemTile(int index, _FoodItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text(item.qtyLabel, style: const TextStyle(color: Colors.black54)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${item.kcal} Cal', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showItemMenu(index),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Icon(Icons.more_vert, size: 20, color: Colors.black54),
            ),
          ),
        ]),
      ),
    );
  }

  // navigate helper to open SearchMealScreen
  Future<void> _openSearchMealScreen() async {
    // You can await a result if SearchMealScreen returns a picked item.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchMealScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: Text('Add to ${widget.mealName}', style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: BackButton(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(child: Text(_todayLabel(), style: const TextStyle(color: Colors.black54, fontSize: 13))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _summaryCard(context),

            const SizedBox(height: 12),

            // row with "Meal" label and a SEARCH-BAR style tappable area on right
            Row(
              children: [
                const Text('Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                // new search-bar-like control replacing the small + circle
                InkWell(
                  onTap: _openSearchMealScreen,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    width: 180, // small rounded search field
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0,3))],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, size: 20, color: Colors.black54),
                        SizedBox(width: 8),
                        Expanded(child: Text('+ Meal', style: TextStyle(color: Colors.black54))),
                        // if you want a plus at the far right you can add it; omitted to match "convert + into search"
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _items.isEmpty
                  ? Center(child: Text('No items yet. Tap the search or + to add to ${widget.mealName}.', style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, i) => _itemTile(i, _items[i]),
              ),
            ),

            SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        // open search screen when bottom "Add item" pressed
                        await _openSearchMealScreen();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Add item', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _items);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidRingPainterMock extends CustomPainter {
  final double progress;
  final double ringWidth;
  final Color ringColor;
  final Color baseColor;
  _SolidRingPainterMock({
    required this.progress,
    required this.ringWidth,
    required this.ringColor,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = (min(size.width, size.height) - ringWidth) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..color = baseColor;
    canvas.drawCircle(center, radius, base);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..color = ringColor;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi/2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SolidRingPainterMock oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringWidth != ringWidth || oldDelegate.ringColor != ringColor;
  }
}
