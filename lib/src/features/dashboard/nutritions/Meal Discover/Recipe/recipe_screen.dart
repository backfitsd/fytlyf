// file: lib/src/features/dashboard/nutritions/recipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Recipe {
  final String name;
  final String description;
  final bool isVeg; // true => veg, false => non-veg
  final int likes;

  Recipe({
    required this.name,
    required this.description,
    required this.isVeg,
    this.likes = 0,
  });
}

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({Key? key}) : super(key: key);

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  // realistic sample data with veg/non-veg flags
  final List<Recipe> allRecipes = [
    Recipe(name: 'Oats Pancake', description: 'Healthy breakfast pancake made with oats.', isVeg: true, likes: 120),
    Recipe(name: 'Grilled Veg Sandwich', description: 'Loaded with grilled veggies & cheese.', isVeg: true, likes: 230),
    Recipe(name: 'Salmon with Quinoa', description: 'Protein rich salmon paired with quinoa.', isVeg: false, likes: 85),
    Recipe(name: 'Paneer Tikka', description: 'Spiced paneer, perfect for veg lovers.', isVeg: true, likes: 410),
    Recipe(name: 'Chicken Biryani', description: 'Aromatic chicken biryani with layers of flavor.', isVeg: false, likes: 980),
    Recipe(name: 'Avocado Toast', description: 'Quick & creamy avocado on sourdough.', isVeg: true, likes: 58),
  ];

  final List<String> tabs = ['Explore', 'New', 'Favourite', 'Menu'];

  int selectedTabIndex = 0;

  // NOTE: false => Veg (off). true => Non-veg (on).
  bool isNonVeg = false;

  // Inline SVG strings for small circle icons (green/red)
  final String _vegCircleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10" fill="#22C55E"/>
</svg>
''';

  final String _nonVegCircleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10" fill="#EF4444"/>
</svg>
''';

  void _toggleVegNonVeg() => setState(() => isNonVeg = !isNonVeg);

  void _onSearchTap() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  List<Recipe> get _filteredRecipes {
    return allRecipes.where((r) => isNonVeg ? !r.isVeg : r.isVeg).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFF3D00), Color(0xFFFF6D00), Color(0xFFFFA726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final filtered = _filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
          child: Column(
            children: [
              // SEARCH ROW (search expands, toggle fixed/adaptive width)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search box - expands to take remaining space
                  Expanded(
                    child: GestureDetector(
                      onTap: _onSearchTap,
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Search', style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Adaptive fixed toggle area - will NOT push the row beyond width
                  AdaptiveToggleContainer(
                    isOn: isNonVeg,
                    onTap: _toggleVegNonVeg,
                    vegSvg: _vegCircleSvg,
                    nonVegSvg: _nonVegCircleSvg,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tabs
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = selectedTabIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => selectedTabIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? Colors.grey.shade300 : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            tabs[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Recipe list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text(isNonVeg ? 'No non-veg dishes found.' : 'No veg dishes found.',
                      style: const TextStyle(color: Colors.grey)),
                )
                    : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              color: Colors.grey.shade200,
                            ),
                            child: Stack(
                              children: [
                                const Center(child: Icon(Icons.image, size: 56, color: Colors.grey)),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(r.description,
                                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                  ),
                                ),

                                // small veg/non-veg marker on top-left of the card image
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: r.isVeg ? SvgPicture.string(_vegCircleSvg) : SvgPicture.string(_nonVegCircleSvg),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 1, color: Colors.grey.shade200),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.favorite_border, size: 20),
                                    const SizedBox(width: 6),
                                    Text(r.likes >= 1000 ? '${(r.likes / 1000).toStringAsFixed(1)}k' : '${r.likes}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container that positions the adaptive toggle and guarantees fixed/adaptive width,
/// preventing RenderFlex overflow on narrow screens.
class AdaptiveToggleContainer extends StatelessWidget {
  final bool isOn;
  final VoidCallback onTap;
  final String? vegSvg;
  final String? nonVegSvg;

  const AdaptiveToggleContainer({
    Key? key,
    required this.isOn,
    required this.onTap,
    this.vegSvg,
    this.nonVegSvg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Outer padding to keep spacing consistent with search box
    return LayoutBuilder(builder: (context, constraints) {
      // If parent has little width, make the toggle smaller.
      // Pixel 9a width ~ 360 dp, so these clamp values are safe.
      final double available = constraints.maxWidth.isFinite ? constraints.maxWidth.toDouble() : 84.0;
      // We pick a width not greater than 86 and not less than 48.
      final double preferredWidth = available.clamp(48.0, 86.0).toDouble();

      return SizedBox(
        width: preferredWidth,
        child: Semantics(
          button: true,
          label: isOn ? 'Non-veg filter on' : 'Veg filter on',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: AnimatedToggleProfessional(
                isOn: isOn,
                vegSvg: vegSvg,
                nonVegSvg: nonVegSvg,
                width: preferredWidth,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// A polished professional animated toggle:
/// - AnimatedContainer for background color transition
/// - AnimatedPositioned for thumb slide
/// - AnimatedOpacity/Scale for label transitions
class AnimatedToggleProfessional extends StatelessWidget {
  final bool isOn;
  final double width;
  final String? vegSvg;
  final String? nonVegSvg;

  const AnimatedToggleProfessional({
    Key? key,
    required this.isOn,
    required this.width,
    this.vegSvg,
    this.nonVegSvg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vegColor = const Color(0xFF22C55E);
    final nonVegColor = const Color(0xFFEF4444);

    // FIXED: Convert clamp() output to double using .toDouble()
    final double height = (width * 0.42).clamp(28.0, 36.0).toDouble();
    final double padding = (height * 0.12).clamp(3.0, 6.0).toDouble();
    final double thumbSize = (height - padding * 2).clamp(16.0, 28.0).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isOn ? nonVegColor.withOpacity(0.12) : vegColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Stack(
        children: [
          // Labels: Veg (left) & Non-veg (right)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Veg label
                AnimatedOpacity(
                  opacity: isOn ? 0.7 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: EdgeInsets.only(left: padding + 2),
                    child: AnimatedScale(
                      scale: isOn ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        'Veg',
                        style: TextStyle(
                          fontSize: (height * 0.36).clamp(10.0, 12.0).toDouble(),
                          fontWeight: FontWeight.w700,
                          color: isOn ? Colors.grey.shade600 : vegColor,
                        ),
                      ),
                    ),
                  ),
                ),
                // Non-veg label
                AnimatedOpacity(
                  opacity: isOn ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: EdgeInsets.only(right: padding + 2),
                    child: AnimatedScale(
                      scale: isOn ? 1.0 : 0.95,
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        'Non-veg',
                        style: TextStyle(
                          fontSize: (height * 0.36).clamp(10.0, 12.0).toDouble(),
                          fontWeight: FontWeight.w700,
                          color: isOn ? nonVegColor : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thumb
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            left: isOn ? width - thumbSize - padding : padding,
            top: (height - thumbSize) / 2 - padding / 4,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: isOn ? nonVegColor : vegColor,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Center(
                child: (isOn && nonVegSvg != null) || (!isOn && vegSvg != null)
                    ? SizedBox(
                  width: thumbSize * 0.55,
                  height: thumbSize * 0.55,
                  child: SvgPicture.string(isOn ? nonVegSvg! : vegSvg!),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder Search Screen
class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Search Meals")), body: const Center(child: Text("Implement your search screen here")));
  }
}
