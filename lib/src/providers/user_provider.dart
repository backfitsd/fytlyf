import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fyt_user_model.dart';

/// 🔥 Streams the current user's Firestore data as a typed [FytUserModel].
final fytUserProvider = StreamProvider<FytUserModel?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  // Enable offline caching
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => FytUserModel.fromFirestore(snap.data(), uid));
});
