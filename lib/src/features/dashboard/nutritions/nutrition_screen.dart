// file: lib/src/features/dashboard/nutritions/nutrition_screen.dart
// READY-TO-PASTE — Firestore-backed NutritionScreen (Option A storage)
// Preserves UI — only wiring & data added for water (ml)

/*
  NOTES:
  - Only water backend & displayed text changed (to ml).
  - UI layout, widgets, styles are unchanged EXCEPT:
      * the minus icon inside the wheel popup has been removed
      * when user taps the plus icon in the picker, a confirmation bottom sheet appears;
        if confirmed, the add is saved to Firestore via WaterRepository.addWater(uid, ml)
  - currentWater and goalWater are in ML (int).
  - Water storage expected:
      users/{uid}/water/{yyyy-MM-dd}:
        entries: [250, 500, ...]
  - This file relies on the minimal WaterRepository available at:
      lib/src/features/dashboard/nutritions/services/water_repository.dart
*/

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// local screens (unchanged)
import 'Meal Discover/Meal Planner/meal_tracking_screen.dart';
import 'Meal Discover/Recommend/recommend_screen.dart';
import 'Meal Discover/Recipe/recipe_screen.dart';
import 'Meal Discover/AI Meal/ai_meal_planner_screen.dart';
import 'water_screen.dart';
import 'Meal Discover/Meal Planner/search_meal_screen.dart';

// <-- NEW: Use local nutrition JSON DB to compute values -->
import 'services/nutrition_database.dart';

// <-- NEW: Minimal water repository (pure entries list) -->
import 'services/water_repository.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const LinearGradient _appGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Firestore & Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Live values (defaults)
  int currentCalories = 0;
  int calorieTarget = 2500;

  double protCurrent = 0.0;
  double protTarget = 70.0;

  double carbsCurrent = 0.0;
  double carbsTarget = 250.0;

  double fatCurrent = 0.0;
  double fatTarget = 70.0;

  // === CHANGED: water in ML (integers) ===
  int currentWater = 0; // ml
  int goalWater = 2500; // ml (default)

  bool _loading = true;

  // Known meal sections (matches MealTrackingScreen)
  final List<String> _mealNames = [
    'Breakfast',
    'Morning Snack',
    'Lunch',
    'Evening Snack',
    'Dinner',
    'Others',
  ];

  // subscription handles to cancel on dispose
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ctrl.forward();

    // ensure nutrition DB loaded (safe if called elsewhere)
    NutritionDatabase.init().catchError((_) {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachListenersOptionA(); // Option A wiring (meals + water)
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _ctrl.dispose();
    super.dispose();
  }

  // Format date to YYYY-MM-DD
  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // short month name
  String _monthName(int m) {
    const list = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return list[m - 1];
  }

  // ----------------------------
  // Option A listeners: Firestore stores minimal meal fields:
  // { id, unit, amount, gram_weight, added_at }
  // Use NutritionDatabase JSON to compute nutrition values on read.
  // Also: wire water to minimal 'water' collection (entries: [ints])
  // ----------------------------
  void _attachListenersOptionA() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final todayKey = _formatDate(DateTime.now());

    // 1) nutrition_targets doc (single) — same as before
    final targetsRef = _db.collection('users').doc(uid).collection('meta').doc('nutrition_targets');
    final altTargetsRef = _db.collection('users').doc(uid).collection('nutrition').doc('targets');

    final targetsSub = targetsRef.snapshots().listen((snap) {
      if (!mounted) return;
      if (snap.exists) {
        final data = snap.data() ?? {};
        _applyTargetsFromDocData(data);
      } else {
        altTargetsRef.get().then((alt) {
          if (alt.exists) _applyTargetsFromDocData(alt.data() ?? {});
        }).catchError((e){});
      }
    }, onError: (e) {
      debugPrint('targets snapshot error: $e');
      altTargetsRef.get().then((alt) {
        if (alt.exists) _applyTargetsFromDocData(alt.data() ?? {});
      }).catchError((_) {});
    });
    _subs.add(targetsSub);

    // 2) water for today — REWIRED to minimal 'water' doc (entries: [ints])
    // Listen to user's water doc for today (minimal reads — one doc)
    final waterRef = _db.collection('users').doc(uid).collection('water').doc(todayKey);
    final waterSub = waterRef.snapshots().listen((snap) {
      if (!mounted) return;
      if (snap.exists) {
        final data = snap.data() ?? {};
        // entries: [ints]
        final entriesRaw = data['entries'];
        if (entriesRaw == null) {
          currentWater = 0;
        } else {
          try {
            final List<int> entries = List<int>.from((entriesRaw as List).map((e) => (e as num).toInt()));
            currentWater = entries.fold<int>(0, (p, e) => p + e);
          } catch (e) {
            currentWater = 0;
          }
        }
      } else {
        currentWater = 0;
      }
      if (mounted) setState(() { _loading = false; });
    }, onError: (e) {
      debugPrint('water snapshot error: $e');
      if (mounted) setState(() { _loading = false; });
    });
    _subs.add(waterSub);

    // 3) Listen to each meal subcollection and compute sums using JSON DB
    final Map<String, int> mealKcal = { for (var m in _mealNames) m : 0 };
    final Map<String, double> mealProt = { for (var m in _mealNames) m : 0.0 };
    final Map<String, double> mealCarbs = { for (var m in _mealNames) m : 0.0 };
    final Map<String, double> mealFat = { for (var m in _mealNames) m : 0.0 };

    for (final meal in _mealNames) {
      final colRef = _db.collection('users').doc(uid).collection('meals').doc(todayKey).collection(meal);
      final sub = colRef.snapshots().listen((snap) async {
        if (!mounted) return;

        int kcalSum = 0;
        double protSum = 0.0;
        double carbsSum = 0.0;
        double fatSum = 0.0;

        // Ensure nutrition DB loaded (synchronous read from memory)
        final foods = NutritionDatabase.all; // List<dynamic>
        for (final d in snap.docs) {
          final data = d.data();

          // Expected minimal storage: id, unit, amount, gram_weight
          final dynamic rawId = data['id'] ?? data['foodId'] ?? data['fid'];
          final String idStr = rawId?.toString() ?? '';

          // prefer stored gram_weight if present (developer suggested storing gram_weight)
          double grams = 0.0;
          if (data.containsKey('gram_weight')) {
            try {
              grams = (data['gram_weight'] is num) ? (data['gram_weight'] as num).toDouble() : double.parse(data['gram_weight'].toString());
            } catch (_) {
              grams = 0.0;
            }
          } else {
            // fallback: try to compute from unit + amount using JSON measures
            final unit = (data['unit'] ?? '').toString();
            final num amountNum = (data['amount'] ?? data['qty'] ?? 0) is num
                ? (data['amount'] ?? data['qty'] ?? 0) as num
                : num.tryParse((data['amount'] ?? data['qty'] ?? '0').toString()) ?? 0;
            final double amount = amountNum.toDouble();

            // find food entry
            final food = foods.firstWhere(
                    (f) => f != null && f['id'] != null && f['id'].toString() == idStr,
                orElse: () => null);

            if (food != null) {
              try {
                final measures = (food['measures'] is Map) ? Map<String, dynamic>.from(food['measures']) : <String, dynamic>{};
                final baseMeasureGram = (measures[unit] ?? 0);
                if (baseMeasureGram is num) {
                  grams = baseMeasureGram.toDouble() * amount;
                } else if (baseMeasureGram is String) {
                  grams = double.tryParse(baseMeasureGram) ?? 0.0;
                  grams = grams * amount;
                } else {
                  grams = 0.0;
                }
              } catch (e) {
                grams = 0.0;
              }
            } else {
              grams = 0.0;
            }
          }

          // If grams still zero, try to compute using amount assuming base_weight_gram * amount
          if (grams <= 0) {
            final foods = NutritionDatabase.all;
            final food = foods.firstWhere(
                    (f) => f != null && f['id'] != null && f['id'].toString() == idStr,
                orElse: () => null);
            if (food != null) {
              final baseW = (food['base_weight_gram'] ?? 100);
              double baseWG = (baseW is num) ? baseW.toDouble() : double.tryParse(baseW.toString()) ?? 100.0;
              final num amountNum = (data['amount'] ?? 1) is num ? (data['amount'] ?? 1) as num : num.tryParse((data['amount'] ?? '1').toString()) ?? 1;
              grams = baseWG * amountNum.toDouble();
            }
          }

          // Now compute nutrition using the JSON entry
          final foodEntry = NutritionDatabase.all.firstWhere(
                (f) => f != null && f['id'] != null && f['id'].toString() == idStr,
            orElse: () => null,
          );

          if (foodEntry == null) {
            // can't compute without food info — skip (debug)
            debugPrint('Nutrition DB missing id=$idStr — cannot compute nutrition for a meal item.');
            continue;
          }

          final per100 = (foodEntry['nutrition_per_100g'] is Map) ? Map<String, dynamic>.from(foodEntry['nutrition_per_100g']) : <String, dynamic>{};
          final num calPer100 = (per100['calories'] ?? per100['cal'] ?? 0) as num;
          final num protPer100 = (per100['protein'] ?? 0) as num;
          final num carbsPer100 = (per100['carbs'] ?? 0) as num;
          final num fatPer100 = (per100['fat'] ?? 0) as num;

          final double factor = (grams / 100.0);

          final int kcalItem = (calPer100.toDouble() * factor).round();
          final double protItem = protPer100.toDouble() * factor;
          final double carbsItem = carbsPer100.toDouble() * factor;
          final double fatItem = fatPer100.toDouble() * factor;

          kcalSum += kcalItem;
          protSum += protItem;
          carbsSum += carbsItem;
          fatSum += fatItem;
        } // end docs loop

        mealKcal[meal] = kcalSum;
        mealProt[meal] = protSum;
        mealCarbs[meal] = carbsSum;
        mealFat[meal] = fatSum;

        // compute totals
        final totalKcal = mealKcal.values.fold<int>(0, (p, e) => p + e);
        final totalProt = mealProt.values.fold<double>(0.0, (p, e) => p + e);
        final totalCarbs = mealCarbs.values.fold<double>(0.0, (p, e) => p + e);
        final totalFat = mealFat.values.fold<double>(0.0, (p, e) => p + e);

        currentCalories = totalKcal;
        protCurrent = protSum;
        carbsCurrent = totalCarbs;
        fatCurrent = totalFat;

        if (mounted) setState(() {
          _loading = false;
        });
      }, onError: (e) {
        debugPrint('meal collection snapshot error ($meal): $e');
        if (mounted) setState(() { _loading = false; });
      });

      _subs.add(sub);
    }

    // Done attaching listeners.
  }

  // Apply nutrition_targets doc into local targets
  void _applyTargetsFromDocData(Map<String, dynamic> data) {
    try {
      if (data['calories'] is Map) {
        final c = Map<String, dynamic>.from(data['calories']);
        calorieTarget = (c['target'] ?? calorieTarget).toInt();
      } else if (data['calories'] is num) {
        calorieTarget = (data['calories'] ?? calorieTarget).toInt();
      }

      if (data['macros'] is Map) {
        final macros = Map<String, dynamic>.from(data['macros']);
        if (macros['protein'] is Map) {
          final p = Map<String, dynamic>.from(macros['protein']);
          protTarget = (p['target'] ?? protTarget).toDouble();
        } else if (macros['protein'] is num) {
          protTarget = (macros['protein'] ?? protTarget).toDouble();
        }

        if (macros['carbs'] is Map) {
          final c = Map<String, dynamic>.from(macros['carbs']);
          carbsTarget = (c['target'] ?? carbsTarget).toDouble();
        } else if (macros['carbs'] is num) {
          carbsTarget = (macros['carbs'] ?? carbsTarget).toDouble();
        }

        if (macros['fat'] is Map) {
          final f = Map<String, dynamic>.from(macros['fat']);
          fatTarget = (f['target'] ?? fatTarget).toDouble();
        } else if (macros['fat'] is num) {
          fatTarget = (macros['fat'] ?? fatTarget).toDouble();
        }
      }

      if (mounted) setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint('applyTargets error: $e');
    }
  }

  // ---------------------------
  // NEW: Save water (ml) via minimal WaterRepository
  // ---------------------------
  Future<void> _saveWaterMl(int mlToAdd) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await WaterRepository.addWater(uid, mlToAdd);

      // After writing, fetch today's entries and update currentWater (ml)
      final id = _formatDate(DateTime.now());
      final list = await WaterRepository.getDate(uid, id);
      final totalMl = list.fold<int>(0, (p, e) => p + e);

      setState(() {
        currentWater = totalMl;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed saving water ml: $e');
    }
  }

  // ---------------------------
  // Helper: show confirmation bottom sheet for adding ml (when + is tapped)
  // ---------------------------
  Future<bool> _confirmAddBottomSheet(BuildContext context, int ml) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text('Add Water', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Add $ml ml to today\'s water?', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).then((v) => v ?? false);
  }

  // ---------------------------
  // POPUP: reused wheel dialog for water — visuals unchanged,
  // internal logic converted to ML and text displays "1200 ml / 2500 ml"
  // ---------------------------
  Future<void> _showWaterDialogAndSave(BuildContext context) async {
    // working values in ML
    int tempWaterMl = currentWater; // ml (start with current total)
    int selectedAmount = 250; // ml
    const int maxAmount = 1000;
    const int step = 10;

    final scrollController = FixedExtentScrollController(initialItem: selectedAmount ~/ step);

    await showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        final wheelItemExtent = height * 0.03;
        final wheelVisibleHeight = wheelItemExtent * 3;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: width * 0.08),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Hydration", style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.w800)),
                        Text("Today, ${_monthName(DateTime.now().month)} ${DateTime.now().day}", style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.w500, color: Colors.black54)),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: width * 0.35,
                                    width: width * 0.35,
                                    child: CircularProgressIndicator(
                                      value: (tempWaterMl / goalWater).clamp(0.0, 1.0),
                                      strokeWidth: 9,
                                      backgroundColor: Colors.blueAccent.withOpacity(0.15),
                                      valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                                    ),
                                  ),
                                  Icon(Icons.water_drop_rounded, size: width * 0.06, color: Colors.blueAccent),
                                ],
                              ),
                              SizedBox(height: height * 0.015),
                              // TEXT CHANGED TO ML (Format A: "1200 ml / 2500 ml")
                              Text("${tempWaterMl} ml / ${goalWater} ml", style: TextStyle(fontSize: width * 0.037, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Text("Select water (ml)", style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.w600, color: Colors.black87)),
                              SizedBox(height: height * 0.01),
                              SizedBox(
                                height: wheelVisibleHeight,
                                child: ListWheelScrollView.useDelegate(
                                  controller: scrollController,
                                  itemExtent: wheelItemExtent,
                                  physics: const FixedExtentScrollPhysics(),
                                  overAndUnderCenterOpacity: 0.5,
                                  onSelectedItemChanged: (index) {
                                    dialogSetState(() {
                                      selectedAmount = index * step;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: (maxAmount ~/ step) + 1,
                                    builder: (context, index) {
                                      int value = index * step;
                                      bool isSelected = value == selectedAmount;
                                      return AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 150),
                                        style: TextStyle(
                                          fontSize: isSelected ? width * 0.045 : width * 0.038,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? Colors.blueAccent : Colors.black38,
                                        ),
                                        child: Text("$value ml"),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.015),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // MINUS BUTTON REMOVED AS REQUESTED
                                  // ONLY PLUS BUTTON REMAINS — when tapped, will ask for confirmation
                                  InkWell(
                                    onTap: () async {
                                      // Show confirmation bottom sheet to confirm adding selectedAmount
                                      final confirmed = await _confirmAddBottomSheet(context, selectedAmount);
                                      if (confirmed) {
                                        // Immediately add selectedAmount to Firestore
                                        await _saveWaterMl(selectedAmount);

                                        // update tempWaterMl locally to reflect added ml in the dialog
                                        dialogSetState(() {
                                          tempWaterMl += selectedAmount;
                                          if (tempWaterMl > goalWater) tempWaterMl = goalWater;
                                        });
                                      }
                                    },
                                    child: const Icon(Icons.add_circle_outline, size: 30, color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    _exploreButton(
                      context,
                      onTap: () async {
                        // calculate delta in ml and save only the delta
                        final int delta = tempWaterMl - currentWater;
                        if (delta != 0) {
                          // if delta > 0: add ml; if delta < 0: do not add negative
                          if (delta > 0) {
                            await _saveWaterMl(delta);
                          } else {
                            // do nothing for negative deltas to keep minimal add-only model
                          }
                        }

                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen()));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Open Add Meal → Search flow. As requested, when started from NutritionScreen,
  // MealInfoScreen will ask which meal to add to.
  Future<void> _openAddMealFlow() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchMealScreen()),
    );
    if (res != null) {
      // no-op; listeners will refresh UI
    }
  }

  void _openMealTracking() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MealTrackingScreen()));
  }

  void _openWaterScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen()));
  }

  double _safeProgress(double current, double target) {
    if (target <= 0) return 0.0;
    return (current / target).clamp(0.0, 1.0);
  }

  // UI helper: EXPLORE button used inside water dialog
  Widget _exploreButton(BuildContext context, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap ?? () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: _appGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "EXPLORE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height >= size.width;

    final double cardHeight = (isPortrait
        ? size.height.clamp(560.0, 1000.0) * 0.25 * 1.2
        : size.height.clamp(360.0, 800.0) * 0.35 * 1.2)
        .toDouble();

    final int current = currentCalories;
    final int goal = calorieTarget;
    final double progressRaw = goal == 0 ? 0.0 : (current / goal);

    String _motivation(double p) {
      if (p <= 0.15) return "A true start is a gentle one.\nSmall steps build strong habits.";
      if (p <= 0.35) return "Good momentum.\nKeep choices steady and simple.";
      if (p <= 0.6) return "Great balance.\nFuel up and stay consistent.";
      if (p <= 0.85) return "Strong progress.\nAlign the next meal to your goal.";
      if (p <= 1.0) return "Right on target.\nTiny tweaks make perfect days.";
      return "You’re above target.\nGo lighter now and hydrate well.";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              Material(
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: _appGradient,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nutrition',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          // show TODAY only as confirmed
                          'Today, ${_monthName(DateTime.now().month)} ${DateTime.now().day}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: SizedBox(
                        height: cardHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cw = constraints.maxWidth;
                              final ch = constraints.maxHeight;

                              double ringSize = (min(cw, ch) * 0.65 * 1.2 * 1.2)
                                  .clamp(90.0, min(cw * 0.98, ch * 0.98));
                              final double ringWidth = (ringSize * 0.07).clamp(3.0, 7.0).toDouble();

                              final double iconSize = ((ringSize / 1.5) * 0.42).toDouble();
                              final double vGapSmall = (ch * 0.02).clamp(6.0, 14.0).toDouble();
                              final Color calorieColor = _calorieSolidColor(progressRaw);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: vGapSmall * 0.5),
                                  const Text(
                                    'Calorie',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: vGapSmall * 1.4 * 1.1),
                                  Center(
                                    child: AnimatedBuilder(
                                      animation: _ctrl,
                                      builder: (context, _) {
                                        final animatedProgress = (_ctrl.value * progressRaw).clamp(0.0, 1.0);
                                        return _SolidRingWithIcon(
                                          size: ringSize,
                                          ringWidth: ringWidth,
                                          progress: animatedProgress,
                                          baseColor: const Color(0xFFE8F2FF),
                                          ringColor: calorieColor,
                                          icon: Iconsax.flash,
                                          iconSize: iconSize,
                                          onTap: _openMealTracking,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: vGapSmall * 1.3 * 1.2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: GestureDetector(
                                      onTap: _openMealTracking,
                                      child: Text(
                                        '$current/${goal} Cal',
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                                    child: Text(
                                      _motivation(progressRaw),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      maxLines: 3,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: SizedBox(
                        height: cardHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double cw = constraints.maxWidth;
                              final double ch = constraints.maxHeight;
                              const double hGap = 14, vGap = 16;
                              final double colWidth = ((cw - hGap) / 2);
                              final double rowHeight = ((ch - vGap) / 2);

                              final double ringSize = (min(colWidth, rowHeight) * 0.7).clamp(44.0, 120.0).toDouble();
                              final double ringWidth = (ringSize * 0.07).clamp(3.0, 6.0).toDouble();
                              final double titleSize = (ringSize * 0.26).clamp(12.0, 17.0).toDouble();
                              final double valueSize = (ringSize * 0.23 * 0.8 * 1.1).clamp(9.0, 15.0).toDouble();

                              Widget buildCell(String title, IconData icon, double targetProgress, String value, Color color, {bool isWater = false}) {
                                // CHANGED: displayValue for water shows ML (format A)
                                final String displayValue = isWater ? '${currentWater} ml / ${goalWater} ml' : value;
                                final double animatedTarget = targetProgress.clamp(0.0, 1.0);

                                Widget content = SizedBox(
                                  width: colWidth,
                                  height: rowHeight,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedBuilder(
                                        animation: _ctrl,
                                        builder: (context, _) {
                                          final animatedProgress = (_ctrl.value * animatedTarget).clamp(0.0, 1.0);
                                          return _SolidRingWithIcon(
                                            size: ringSize,
                                            ringWidth: ringWidth,
                                            progress: animatedProgress,
                                            baseColor: const Color(0xFFE8F2FF),
                                            ringColor: color,
                                            icon: icon,
                                            iconSize: (ringSize * 0.42).clamp(16.0, ringSize * 0.55).toDouble(),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          if (isWater) {
                                            _openWaterScreen();
                                          } else {
                                            _openMealTracking();
                                          }
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            displayValue,
                                            style: TextStyle(fontSize: valueSize, color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (isWater) {
                                  return GestureDetector(onTap: _openWaterScreen, child: content);
                                } else {
                                  return GestureDetector(onTap: _openMealTracking, child: content);
                                }
                              }

                              final proteinProg = _safeProgress(protCurrent, protTarget);
                              final carbsProg = _safeProgress(carbsCurrent, carbsTarget);
                              final fatProg = _safeProgress(fatCurrent, fatTarget);
                              final waterProg = _safeProgress(currentWater.toDouble(), goalWater.toDouble());

                              return Column(children: [
                                Row(
                                  children: [
                                    buildCell('Protein', Iconsax.cup, proteinProg, '${protCurrent.toInt()}/${protTarget.toInt()}g', const Color(0xFF42A5F5)),
                                    const SizedBox(width: hGap),
                                    buildCell('Carbs', Iconsax.ranking, carbsProg, '${carbsCurrent.toInt()}/${carbsTarget.toInt()}g', const Color(0xFF66BB6A)),
                                  ],
                                ),
                                const SizedBox(height: vGap),
                                Row(
                                  children: [
                                    buildCell('Fat', Iconsax.coffee, fatProg, '${fatCurrent.toInt()}/${fatTarget.toInt()}g', const Color(0xFFFB8C00)),
                                    const SizedBox(width: hGap),
                                    buildCell('Water', Iconsax.glass, waterProg, '${currentWater} ml / ${goalWater} ml', const Color(0xFF64B5FF), isWater: true),
                                  ],
                                ),
                              ]);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: min(160, size.width * 0.34),
                        height: 48,
                        child: GradientBorderButton(
                          gradient: _appGradient,
                          onPressed: _openAddMealFlow,
                          icon: const Icon(Icons.add, size: 18, color: Colors.black87),
                          label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: min(320, size.width * 0.48),
                        height: 48,
                        child: GradientBorderButton(
                          gradient: _appGradient,
                          onPressed: () => _showWaterDialogAndSave(context),
                          icon: const Icon(Icons.local_drink, size: 18, color: Colors.blue),
                          label: const Text('Add Water Intake', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, layoutConstraints) {
                final double availableWidth = layoutConstraints.maxWidth;
                const double hSpacing = 12.0;
                final double cardWidth = (availableWidth - hSpacing) / 2;
                final double cardHeight = (cardWidth * 0.75).clamp(110.0, 180.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        'Meal Discover',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: hSpacing,
                      runSpacing: 12,
                      children: [
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/meal_planner.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealTrackingScreen())),
                        ),
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/recommend.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendScreen())),
                        ),
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/recipe.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeScreen())),
                        ),
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/ai_planner.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiMealPlannerScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// rest of file unchanged


// NOTE: The remainder of the helper widgets (_SolidRingWithIcon, _SolidRingPainter,
// _featureCard, GradientBorderButton, _calorieSolidColor, etc.) are included below
// exactly as in your original file (unchanged).
//
// I'm appending them verbatim to ensure the file is complete and compiles.

/// Gradient bordered button — white inner fill with gradient stroke.
class GradientBorderButton extends StatelessWidget {
  final LinearGradient gradient;
  final Widget label;
  final Widget icon;
  final VoidCallback? onPressed;
  final double borderWidth;
  final double borderRadius;

  const GradientBorderButton({
    Key? key,
    required this.gradient,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.black87),
                    child: label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _calorieSolidColor(double p) {
  if (p <= 0.2) return const Color(0xFFFFD54F);
  if (p <= 0.6) return const Color(0xFFFB8C00);
  if (p <= 1.0) return const Color(0xFFE53935);
  return const Color(0xFFB71C1C);
}

class _SolidRingWithIcon extends StatelessWidget {
  final double size, ringWidth, progress, iconSize;
  final Color baseColor, ringColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _SolidRingWithIcon({
    required this.size,
    required this.ringWidth,
    required this.progress,
    required this.baseColor,
    required this.ringColor,
    required this.icon,
    required this.iconSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size / 2)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _SolidRingPainter(
                  progress: progress,
                  ringWidth: ringWidth,
                  ringColor: ringColor,
                  baseColor: baseColor,
                ),
              ),
              Icon(icon, size: iconSize, color: Colors.black87),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolidRingPainter extends CustomPainter {
  final double progress;
  final double ringWidth;
  final Color ringColor;
  final Color baseColor;

  _SolidRingPainter({
    required this.progress,
    required this.ringWidth,
    required this.ringColor,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - ringWidth) / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = baseColor;
    canvas.drawCircle(center, radius, basePaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = ringColor;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _SolidRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.baseColor != baseColor;
  }
}

Widget _featureCard({
  required double width,
  required double height,
  IconData? icon,
  String? title,
  String? subtitle,
  required VoidCallback onTap,
  String? imagePath,
  bool isNetwork = false,
}) {
  const double outerPadding = 0;
  const double innerSpacing = 8.0;
  final bool hasText = (title?.isNotEmpty ?? false) || (subtitle?.isNotEmpty ?? false);
  final double reservedTextArea = hasText ? 48.0 : 0.0;
  final double imageHeight = (height - (outerPadding * 2) - (hasText ? innerSpacing : 0.0) - reservedTextArea)
      .clamp(44.0, height);
  final IconData usedIcon = icon ?? Icons.image;

  Widget imageWidget;
  if (imagePath != null) {
    if (isNetwork) {
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: imageHeight,
        alignment: Alignment.center,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: imageHeight,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (ctx, err, st) => Container(
          width: double.infinity,
          height: imageHeight,
          color: Colors.grey.shade100,
          child: Center(child: Icon(usedIcon, size: 28, color: Colors.black26)),
        ),
      );
    } else {
      imageWidget = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: imageHeight,
        gaplessPlayback: true,
        cacheWidth: 400,
        errorBuilder: (ctx, err, st) => Container(
          width: double.infinity,
          height: imageHeight,
          color: Colors.grey.shade100,
          child: Center(child: Icon(usedIcon, size: 28, color: Colors.black26)),
        ),
      );
    }
  } else {
    imageWidget = Container(
      width: double.infinity,
      height: imageHeight,
      color: Colors.grey.shade100,
      child: Center(child: Icon(usedIcon, size: 28, color: Colors.black54)),
    );
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(outerPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: imageWidget,
              ),
            ),
            if (hasText)
              SizedBox(height: innerSpacing / 1.2)
            else
              const SizedBox(height: 0),
            if (hasText)
              SizedBox(
                height: reservedTextArea,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

