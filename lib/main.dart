import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'src/firebase_options.dart';
import 'src/app.dart';

// ⭐ Add Nutrition Database import
import 'src/features/dashboard/nutritions/services/nutrition_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hide Status Bar for the entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [],
  );

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // ⭐ Initialize Nutrition Database (JSON download + cache)
  await NutritionDatabase.init();

  // ✅ Launch the main app
  runApp(const ProviderScope(child: FytLyfApp()));
}
