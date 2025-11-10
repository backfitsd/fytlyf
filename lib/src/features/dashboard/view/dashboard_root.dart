import 'package:flutter/material.dart';
import 'widgets/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'workout_screen.dart';
import 'community_screen.dart';
import 'nutrition_screen.dart';
import 'rewards_screen.dart';

class DashboardRoot extends StatefulWidget {
  const DashboardRoot({super.key});

  @override
  State<DashboardRoot> createState() => _DashboardRootState();
}

class _DashboardRootState extends State<DashboardRoot> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WorkoutScreen(),
    CommunityScreen(),
    NutritionScreen(),
    RewardsScreen(),
  ];

  void _onNavTap(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🧭 Main PageView (smooth transitions)
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),

      // 🔽 Fixed Bottom Navigation
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onItemTap: _onNavTap,
      ),
    );
  }
}
