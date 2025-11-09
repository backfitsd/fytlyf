import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingDraft {
  String? gender;
  String? goal;
  double? age;
  int? weightKg;
  int? heightCm;
  int? targetWeightKg;
  String? experience;
  String? preference;
  int? weeklyGoal;

  OnboardingDraft({
    this.gender,
    this.goal,
    this.age,
    this.weightKg,
    this.heightCm,
    this.targetWeightKg,
    this.experience,
    this.preference,
    this.weeklyGoal,
  });

  OnboardingDraft copyWith({
    String? gender,
    String? goal,
    double? age,
    int? weightKg,
    int? heightCm,
    int? targetWeightKg,
    String? experience,
    String? preference,
    int? weeklyGoal,
  }) {
    return OnboardingDraft(
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      experience: experience ?? this.experience,
      preference: preference ?? this.preference,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'goal': goal,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'targetWeightKg': targetWeightKg,
      'experience': experience,
      'preference': preference,
      'weeklyGoal': weeklyGoal,
    };
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingNotifier() : super(OnboardingDraft());

  void update(Map<String, dynamic> patch) {
    state = state.copyWith(
      gender: patch['gender'] ?? state.gender,
      goal: patch['goal'] ?? state.goal,
      age: patch['age'] ?? state.age,
      weightKg: patch['weightKg'] ?? state.weightKg,
      heightCm: patch['heightCm'] ?? state.heightCm,
      targetWeightKg: patch['targetWeightKg'] ?? state.targetWeightKg,
      experience: patch['experience'] ?? state.experience,
      preference: patch['preference'] ?? state.preference,
      weeklyGoal: patch['weeklyGoal'] ?? state.weeklyGoal,
    );
  }

  Future<void> save() async {
    // Placeholder: save to Firestore later
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingDraft>(
      (ref) => OnboardingNotifier(),
);
