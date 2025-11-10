import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTap,
  });

  static const List<Color> appGradient = [
    Color(0xFFFF3D00),
    Color(0xFFFF6D00),
    Color(0xFFFFA726),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(Iconsax.home_2, "Home"),
    _NavItem(Icons.fitness_center_rounded, "Workout"),
    _NavItem(Iconsax.people, "Community"),
    _NavItem(Icons.restaurant_menu_rounded, "Nutrition"),
    _NavItem(Iconsax.cup, "Rewards"),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                    (index) => _buildAnimatedIcon(
                  icon: _navItems[index].icon,
                  index: index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon({
    required IconData icon,
    required int index,
  }) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onItemTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AnimatedScale(
          scale: isActive ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: isActive
                ? ShaderMask(
              key: ValueKey('active_$index'),
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: appGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Icon(icon, size: 30, color: Colors.white),
            )
                : Icon(
              key: ValueKey('inactive_$index'),
              icon,
              size: 26,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
