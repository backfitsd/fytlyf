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

  final List<IconData> _icons = const [
    Iconsax.home_2,
    Icons.fitness_center_rounded,
    Iconsax.people,
    Icons.restaurant_menu_rounded,
    Iconsax.cup,
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
          padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 7,
              bottom: 20),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_icons.length, (index) {
                final isActive = currentIndex == index;
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
                          child: Icon(_icons[index],
                              size: 30, color: Colors.white),
                        )
                            : Icon(
                          key: ValueKey('inactive_$index'),
                          _icons[index],
                          size: 26,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
