import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ Added for App Check
import 'package:flutter/services.dart'; // ✅ Needed to hide status bar
import 'src/firebase_options.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hide Status Bar for the entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [], // 🔥 Removes status bar & nav bar
  );

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Firebase App Check with Play Integrity (Android) and DeviceCheck (iOS)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // ✅ Launch the main app
  runApp(const ProviderScope(child: FytLyfApp()));
}
