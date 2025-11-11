import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧩 Professional User Data Model for FYT LYF
class FytUserModel {
  final String uid;
  final String? email;
  final String? name;
  final String? username;
  final String? gender;
  final String? goal;
  final int? age;
  final double? weight;
  final double? height;
  final double? targetWeight;
  final String? experience;
  final String? preference;
  final String? weeklyGoals;
  final Timestamp? createdAt;

  const FytUserModel({
    required this.uid,
    this.email,
    this.name,
    this.username,
    this.gender,
    this.goal,
    this.age,
    this.weight,
    this.height,
    this.targetWeight,
    this.experience,
    this.preference,
    this.weeklyGoals,
    this.createdAt,
  });

  /// Factory constructor for mapping Firestore data
  factory FytUserModel.fromFirestore(Map<String, dynamic>? data, String uid) {
    if (data == null) return FytUserModel(uid: uid);

    return FytUserModel(
      uid: uid,
      email: data['email'],
      name: data['name'],
      username: data['username'],
      gender: data['gender'],
      goal: data['goal'],
      age: (data['age'] is int) ? data['age'] : int.tryParse('${data['age']}'),
      weight: (data['weight'] is num) ? (data['weight'] as num).toDouble() : null,
      height: (data['height'] is num) ? (data['height'] as num).toDouble() : null,
      targetWeight: (data['targetweight'] is num)
          ? (data['targetweight'] as num).toDouble()
          : null,
      experience: data['experience'],
      preference: data['preference'],
      weeklyGoals: data['weeklygoals'],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Convert to Firestore map (useful for updates later)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'username': username,
      'gender': gender,
      'goal': goal,
      'age': age,
      'weight': weight,
      'height': height,
      'targetweight': targetWeight,
      'experience': experience,
      'preference': preference,
      'weeklygoals': weeklyGoals,
      'createdAt': createdAt,
    };
  }
}
