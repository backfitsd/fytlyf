// file: lib/src/features/dashboard/nutritions/recipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Recipe {
  final String name;
  final String description;
  final bool isVeg;
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
  final List<Recipe> allRecipes = [
    Recipe(name: 'Oats Pancake', description: 'Healthy breakfast pancake made with oats.', isVeg: true, likes: 120),
    Recipe(name: 'Grilled Veg Sandwich', description: 'Loaded with grilled veggies & cheese.', isVeg: true, likes: 230),
    Recipe(name: 'Salmon with Quinoa', description: 'Protein rich salmon paired with quinoa.', isVeg: false, likes: 85),
    Recipe(name: 'Paneer Tikka', description: 'Spiced paneer, perfect for veg lovers.', isVeg: true, likes: 410),
    Recipe(name: 'Chicken Biryani', description: 'Aromatic chicken biryani with layers of flavor.', isVeg: false, likes: 980),
    Recipe(name: 'Avocado Toast', description: 'Quick & creamy avocado on sourdough.', isVeg: true, likes: 58),
  ];

  final List<String> tabs = ['Explore', 'New', 'Favorite', 'Menu'];
  int selectedTabIndex = 0;
  bool isNonVeg = false;
  final PageController _pageController = PageController();

  // selectedMenuItem is null when grid is shown; when set, detail view appears inline
  Map<String, dynamic>? selectedMenuItem;

  /// sample menu data: category -> list of dishes (you will replace with real data)
  final Map<String, List<Map<String, dynamic>>> _categoryDishes = {
    'Paneer': List.generate(
      6,
          (i) => {'title': 'Paneer Dish ${i + 1}', 'desc': 'Tasty paneer preparation #${i + 1}', 'likes': 10 + i},
    ),
    'Soyabean': List.generate(
      4,
          (i) => {'title': 'Soyabean Dish ${i + 1}', 'desc': 'Soyabean recipe #${i + 1}', 'likes': 5 + i},
    ),
    'Tofu': List.generate(
      8,
          (i) => {'title': 'Tofu Dish ${i + 1}', 'desc': 'Delicious tofu item #${i + 1}', 'likes': 2 + i},
    ),
    'Rice': List.generate(
      10,
          (i) => {'title': 'Rice Dish ${i + 1}', 'desc': 'Rice based dish #${i + 1}', 'likes': 20 + i},
    ),
  };

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
  void _onSearchTap() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  List<Recipe> get _filteredRecipes => allRecipes.where((r) => isNonVeg ? !r.isVeg : r.isVeg).toList();

  List<Recipe> get _newSuggestions {
    final sorted = [...allRecipes]..sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.take(3).where((r) => isNonVeg ? !r.isVeg : r.isVeg).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // helper to open inline detail
  void _openMenuItem(Map<String, dynamic> item) {
    setState(() => selectedMenuItem = item);
  }

  // helper to close inline detail
  void _closeMenuItem() {
    setState(() => selectedMenuItem = null);
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
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text('Search', style: TextStyle(color: Colors.grey, fontSize: 15))),
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

              // Tabs (tied to PageView)
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = selectedTabIndex == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTabIndex = i;
                          selectedMenuItem = null; // close detail if user switches tab
                        });
                        _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? Colors.grey.shade300 : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(tabs[i], style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // PageView for swipeable pages (Explore / New / Favorite / Menu)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() {
                    selectedTabIndex = index;
                    selectedMenuItem = null; // close detail when swiping away
                  }),
                  children: [
                    // EXPLORE:
                    _buildRecipeListView(_filteredRecipes, emptyMessage: isNonVeg ? 'No non-veg dishes found.' : 'No veg dishes found.'),

                    // NEW:
                    _buildRecipeListView(
                      _newSuggestions,
                      emptyMessage: isNonVeg ? 'No non-veg suggestions.' : 'No veg suggestions.',
                      pageTitle: 'New Suggestions',
                    ),

                    // FAVORITE:
                    _buildPlaceholderScreen(title: 'Favorites', message: 'No favorites yet. Tap ♥ on a recipe to add.'),

                    // MENU: grid or inline detail (keeps header/search/tabs visible)
                    _buildMenuScreenInline(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeListView(List<Recipe> list, {required String emptyMessage, String? pageTitle}) {
    if (list.isEmpty) return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
          child: Column(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), color: Colors.grey.shade200),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.image, size: 56, color: Colors.grey)),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                        child: Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    Positioned(left: 12, top: 12, child: SizedBox(width: 16, height: 16, child: r.isVeg ? SvgPicture.string(_vegCircleSvg) : SvgPicture.string(_nonVegCircleSvg))),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 20),
                        const SizedBox(width: 6),
                        Text(r.likes >= 1000 ? '${(r.likes / 1000).toStringAsFixed(1)}k' : '${r.likes}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderScreen({required String title, required String message}) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text(message, style: const TextStyle(color: Colors.grey))]));
  }

  // ---------- MENU: Inline grid + detail (no navigation) ----------
  Widget _buildMenuScreenInline() {
    final List<Map<String, dynamic>> menuItems = [
      {'name': 'Paneer', 'veg': true, 'count': _categoryDishes['Paneer']!.length},
      {'name': 'Soyabean', 'veg': true, 'count': _categoryDishes['Soyabean']!.length},
      {'name': 'Tofu', 'veg': true, 'count': _categoryDishes['Tofu']!.length},
      {'name': 'Rice', 'veg': true, 'count': _categoryDishes['Rice']!.length},
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: selectedMenuItem == null ? _menuGrid(menuItems) : _menuDetail(selectedMenuItem!),
    );
  }

  // Grid view (shown when selectedMenuItem == null)
  Widget _menuGrid(List<Map<String, dynamic>> menuItems) {
    return Container(
      key: const ValueKey('menuGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: 0.95),
              itemBuilder: (context, idx) {
                final item = menuItems[idx];
                final name = item['name'] as String;
                final veg = item['veg'] as bool;
                final count = item['count'] as int;

                return GestureDetector(
                  onTap: () => _openMenuItem(item),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // circular tile
                      Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                          child: Stack(
                            children: [
                              Center(child: Icon(Icons.fastfood, size: 44, color: Colors.grey.shade600)),
                              Positioned(
                                top: 6,
                                left: 8,
                                child: Container(width: 12, height: 12, decoration: BoxDecoration(color: veg ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                              ),
                              Positioned(top: 6, left: 44, child: Container(width: 20, height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Detail view shown inline under header/tabs (no push)
  // NOTE: removed bottom bar and placed a 'Back to menu' button under the scrollable dish list
  Widget _menuDetail(Map<String, dynamic> item) {
    final String name = item['name'] as String;
    final bool veg = item['veg'] as bool;
    final int count = item['count'] as int;
    final dishes = _categoryDishes[name] ?? [];

    return Container(
      key: const ValueKey('menuDetail'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // top row: small circle at left + title + count on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Small circle tile (top-left)
              Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                  child: Stack(
                    children: [
                      Center(child: Icon(Icons.fastfood, size: 22, color: Colors.grey.shade600)),
                      Positioned(left: 4, top: 4, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: veg ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title with visible underline
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 60, color: Colors.black87),
                  ],
                ),
              ),

              // numeric count on right
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            ],
          ),

          const SizedBox(height: 12),

          // Scrollable list of dishes (fills the large card area)
          Expanded(
            child: Container(
              width: double.infinity,
              // visual card-like container
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))], border: Border.all(color: Colors.grey.shade200)),
              child: dishes.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No dishes available for $name', style: const TextStyle(color: Colors.grey)),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: dishes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final d = dishes[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200), color: Colors.white),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(d['desc'], style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                            Text('${d['likes']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Back to menu button (replaces previous bottom bar)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _closeMenuItem,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.white,
              ),
              child: Text('Back to menu', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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
      final double available = constraints.maxWidth.isFinite ? constraints.maxWidth.toDouble() : 84.0;
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
              child: AnimatedToggleProfessional(isOn: isOn, vegSvg: vegSvg, nonVegSvg: nonVegSvg, width: preferredWidth),
            ),
          ),
        ),
      );
    });
  }
}

/// Animated toggle (unchanged)
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
                AnimatedOpacity(
                  opacity: isOn ? 0.7 : 1.0,
                  duration: const Duration(milliseconds: 220),
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
                AnimatedOpacity(
                  opacity: isOn ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 220),
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
                    ? SizedBox(width: thumbSize * 0.55, height: thumbSize * 0.55, child: SvgPicture.string(isOn ? nonVegSvg! : vegSvg!))
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
