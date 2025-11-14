import 'package:flutter/material.dart';
import 'widgets/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import '../Workout/workout_screen.dart';
import '../Community/community_screen.dart';
import '../nutritions/nutrition_screen.dart';
import '../Rewards/rewards_screen.dart';

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onItemTap: _onNavTap,
      ),
    );
  }
}
