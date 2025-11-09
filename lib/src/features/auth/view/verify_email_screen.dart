// --- file: lib/src/features/auth/view/verify_email_screen.dart ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Onboarding state model
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String pendingUsername; // reserved username
  final String displayName;
  final OnboardingDraft onboarding;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.pendingUsername,
    required this.displayName,
    required this.onboarding,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // start polling every 4s
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        await _finalizeAccount(refreshed);
        return;
      }
    } catch (e) {
      // swallow polling errors
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _finalizeAccount(User user) async {
    // Write user profile + onboarding + link username doc
    final fs = FirebaseFirestore.instance;
    final users = fs.collection('users');
    final usernames = fs.collection('usernames');

    final uid = user.uid;
    final now = FieldValue.serverTimestamp();

    await fs.runTransaction((txn) async {
      txn.set(users.doc(uid), {
        'uid': uid,
        'email': user.email,
        'name': widget.displayName,
        'username': widget.pendingUsername,
        'createdAt': now,
        'lastLogin': now,
        'onboardingCompleted': true,
        'emailVerified': true,
      }, SetOptions(merge: true));

      txn.set(usernames.doc(widget.pendingUsername), {
        'uid': uid,
        'createdAt': now,
      }, SetOptions(merge: true));
    });

    await users.doc(uid).collection('onboarding').doc('data').set({
      'gender': widget.onboarding.gender,
      'goal': widget.onboarding.goal,
      'age': widget.onboarding.age,
      'weightKg': widget.onboarding.weightKg,
      'heightCm': widget.onboarding.heightCm,
      'targetWeightKg': widget.onboarding.targetWeightKg,
      'experience': widget.onboarding.experience,
      'preference': widget.onboarding.preference,
      'weeklyGoal': widget.onboarding.weeklyGoal,
      'savedAt': now,
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.of(context).pop(); // return to auth (or navigate to home)
  }

  @override
  Widget build(BuildContext context) {
    final rf = (MediaQuery.of(context).size.width / 420).clamp(.9, 1.2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify your email'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20 * rf),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We sent a verification link to",
              style: GoogleFonts.roboto(fontSize: 16 * rf),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: GoogleFonts.poppins(
                fontSize: 18 * rf,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Please verify your email to activate your account. Once verified, we’ll finalize your profile and save your onboarding data.",
              style: GoogleFonts.roboto(
                fontSize: 14 * rf,
                color: Colors.black.withValues(alpha: .65),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _resend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      "Resend link",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _checking ? null : _checkVerified,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF3D00)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _checking
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("I verified"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
