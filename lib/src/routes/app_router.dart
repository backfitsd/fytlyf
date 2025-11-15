import 'package:fytlyf/src/features/dashboard/view/dashboard_root.dart' show DashboardRoot;
import 'package:fytlyf/src/features/dashboard/Workout/workout_screen.dart' show WorkoutScreen;
import 'package:fytlyf/src/features/dashboard/Community/community_screen.dart' show CommunityScreen;
import 'package:fytlyf/src/features/dashboard/nutritions/nutrition_screen.dart' show NutritionScreen;
import 'package:fytlyf/src/features/dashboard/Rewards/rewards_screen.dart' show RewardsScreen;
import 'package:go_router/go_router.dart';

// --- Core + Onboarding Imports ---
import '../features/auth/view/auth_entry_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/onboarding/gender_screen.dart';
import '../features/onboarding/goal_screen.dart';
import '../features/onboarding/age_screen.dart';
import '../features/onboarding/weight_height_screen.dart' as wh;
import '../features/onboarding/target_weight_screen.dart';
import '../features/onboarding/experience_screen.dart';
import '../features/onboarding/preference_screen.dart';
import '../features/onboarding/weekly_goals_screen.dart';
import '../features/onboarding/creating_plan_screen.dart';
import '../features/onboarding/progress_graph_screen.dart' show ProgressGraphScreen;

final GoRouter appRouter = GoRouter(
  // ✅ Root route now starts from Splash Screen
  initialLocation: 'splash',
  routes: [
    // ✅ Splash
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ✅ Welcome
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    // ✅ Onboarding Flow
    GoRoute(path: '/onboarding/gender', builder: (context, state) => const GenderScreen()),
    GoRoute(path: '/onboarding/goal', builder: (context, state) => const GoalScreen()),
    GoRoute(path: '/onboarding/age', builder: (context, state) => const AgeScreen()),
    GoRoute(path: '/onboarding/height_weight', builder: (context, state) => const wh.WeightHeightScreen()),
    GoRoute(path: '/onboarding/target_weight', builder: (context, state) => const TargetWeightScreen()),
    GoRoute(path: '/onboarding/experience', builder: (context, state) => const ExperienceScreen()),
    GoRoute(path: '/onboarding/preference', builder: (context, state) => const PreferenceScreen()),
    GoRoute(path: '/onboarding/weekly_goals', builder: (context, state) => const WeeklyGoalsScreen()),
    GoRoute(path: '/onboarding/creating_plan', builder: (context, state) => const CreatingPlanScreen()),
    GoRoute(path: '/onboarding/progress_graph', builder: (context, state) => const ProgressGraphScreen()),

    // ✅ Auth
    GoRoute(
      path: '/auth-entry',
      builder: (context, state) => const AuthEntryScreen(),
    ),

    // ✅ Dashboard Root (Main Entry with Bottom Navigation)
    GoRoute(
      path: '/dashboard-root',
      builder: (context, state) => const DashboardRoot(),
    ),

    // ✅ (Optional Debug Direct Access)
    GoRoute(
      path: '/workout',
      builder: (context, state) => const WorkoutScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/nutrition',
      builder: (context, state) => const NutritionScreen(),
    ),
    GoRoute(
      path: '/rewards',
      builder: (context, state) => const RewardsScreen(),
    ),
  ],
);