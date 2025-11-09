// --- AUTH ENTRY (FYT LYF PROFESSIONAL FINAL VERSION - COMPACT ORANGE SPINNER) ---
// Backend integrated + live username validation + themed compact loading indicator

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';

enum AuthMode { login, signup }

class AuthEntryScreen extends StatefulWidget {
  final String initialTab;
  static const routeName = '/auth/entry';
  const AuthEntryScreen({super.key, this.initialTab = 'signup'});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen>
    with TickerProviderStateMixin {
  AuthMode mode = AuthMode.login;
  final _username = TextEditingController();
  bool _loading = false;
  String? _error;

  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameMessage;
  Timer? _debounce;

  final _users = FirebaseFirestore.instance.collection('users');
  final _usernames = FirebaseFirestore.instance.collection('usernames');

  late final AnimationController _gradientCtrl;
  late final ValueNotifier<bool> _showError;

  static final _usernameReg = RegExp(r'^[a-z0-9._]{4,20}$');
  bool _isUsernameValid(String v) => _usernameReg.hasMatch(v);

  @override
  void initState() {
    super.initState();
    _gradientCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _showError = ValueNotifier(false);
    if (widget.initialTab == 'signup') mode = AuthMode.signup;
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _showError.dispose();
    _username.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _clearError() {
    if (_error != null || _usernameMessage != null) {
      setState(() {
        _error = null;
        _showError.value = false;
        _usernameMessage = null;
      });
    }
  }

  void _setError(String? msg) {
    setState(() => _error = msg);
    _showError.value = msg != null && msg.isNotEmpty;
  }

  OnboardingDraft _readOnboarding() {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(onboardingProvider);
  }

  bool _hasAllOnboardingData() {
    final o = _readOnboarding();
    return o.gender != null &&
        o.goal != null &&
        o.age != null &&
        o.weightKg != null &&
        o.heightCm != null &&
        o.targetWeightKg != null &&
        o.experience != null &&
        o.preference != null &&
        o.weeklyGoal != null;
  }

  Map<String, dynamic> _onboardingToFirestore() {
    final o = _readOnboarding();
    return {
      'gender': o.gender,
      'goal': o.goal,
      'age': o.age,
      'weight': o.weightKg,
      'height': o.heightCm,
      'targetweight': o.targetWeightKg,
      'experience': o.experience,
      'preference': o.preference,
      'weeklygoals': o.weeklyGoal,
    };
  }

  Future<bool> _userDocExists(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.exists;
  }

  Future<bool> _isUsernameFree(String uname) async {
    final snap = await _usernames.doc(uname).get();
    return !snap.exists;
  }

  void _onUsernameChanged(String raw) {
    final value = raw.trim().toLowerCase();
    if (raw != value) {
      final sel = _username.selection;
      _username.value = TextEditingValue(text: value, selection: sel);
    }

    setState(() {
      _usernameAvailable = null;
      _usernameMessage = null;
      _checkingUsername = true;
    });

    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        _checkingUsername = false;
        _usernameMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(seconds: 1), () async {
      if (value.length < 4 || value.length > 20) {
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = false;
          _usernameMessage = "Must be 4–20 characters.";
        });
        return;
      }

      if (!_isUsernameValid(value)) {
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = false;
          _usernameMessage = "Only lowercase letters, numbers, . or _ allowed.";
        });
        return;
      }

      try {
        final free = await _isUsernameFree(value);
        if (!mounted) return;
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = free;
          _usernameMessage =
          free ? "Username available" : "Username not available";
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = null;
          _usernameMessage = null;
        });
      }
    });
  }

  Future<void> _googleLogin() async {
    _setError(null);
    setState(() => _loading = true);
    try {
      final google = await GoogleSignIn().signIn();
      if (google == null) return;
      final auth = await google.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = cred.user!.uid;
      final exists = await _userDocExists(uid);
      if (!exists) {
        await FirebaseAuth.instance.signOut();
        _setError('Account not registered. Please sign up.');
        return;
      }
      if (!mounted) return;
      context.go('/dashboard');
    } catch (_) {
      _setError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignup() async {
    final uname = _username.text.trim().toLowerCase();
    if (!_isUsernameValid(uname) ||
        uname.length < 4 ||
        uname.length > 20 ||
        _usernameAvailable != true) {
      _setError('Enter a valid available username.');
      return;
    }
    if (!_hasAllOnboardingData()) {
      if (!mounted) return;
      context.go('/onboarding/gender');
      return;
    }

    setState(() => _loading = true);
    try {
      final google = await GoogleSignIn().signIn();
      if (google == null) return;

      final auth = await google.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = cred.user!;
      final uid = user.uid;

      if (await _userDocExists(uid)) {
        await FirebaseAuth.instance.signOut();
        _setError('This Google account is already registered.');
        return;
      }

      final unameRef = _usernames.doc(uname);
      if (!(await _isUsernameFree(uname))) {
        await FirebaseAuth.instance.signOut();
        _setError('Username taken. Try another.');
        return;
      }

      await FirebaseFirestore.instance.runTransaction((txn) async {
        txn.set(unameRef, {'uid': uid});
        txn.set(_users.doc(uid), {
          'uid': uid,
          'email': user.email,
          'name': user.displayName,
          'username': uname,
          'createdAt': FieldValue.serverTimestamp(),
          ..._onboardingToFirestore(),
        });
      });

      if (!mounted) return;
      context.go('/dashboard');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final subtitleStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    Widget? usernameSuffix;
    if (_checkingUsername) {
      usernameSuffix = SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: Transform.scale(
            scale: 0.8, // half size spinner
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFFFF6F00), // orange gradient color
            ),
          ),
        ),
      );
    } else if (_usernameAvailable == true) {
      usernameSuffix =
      const Icon(Icons.check_circle, color: Colors.green, size: 25);
    } else if (_usernameAvailable == false) {
      usernameSuffix =
      const Icon(Icons.cancel, color: Colors.red, size: 25);
    }


    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _clearError();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "FYT LYF",
                        style: GoogleFonts.pottaOne(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepOrangeAccent,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("FEEL YOUR TRANSFORMATION", style: subtitleStyle),
                      Text("LOVE YOUR FITNESS", style: subtitleStyle),
                    ],
                  ),
                ),
              ),

              Align(
                alignment: const Alignment(0, -0.25),
                child: _GradientBorderHeader(
                  active: mode,
                  onSelect: (m) {
                    _clearError();
                    setState(() => mode = m);
                  },
                ),
              ),

              Align(
                alignment: const Alignment(0, 0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (mode == AuthMode.signup) ...[
                        const SizedBox(height: 55),
                        AnimatedBuilder(
                          animation: _gradientCtrl,
                          builder: (context, child) {
                            final shift = (1 - _gradientCtrl.value) * 0.6;
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: const [
                                    Color(0xFFFF3D00),
                                    Color(0xFFFFA726),
                                  ],
                                  begin: Alignment(-shift, 0),
                                  end: Alignment(shift, 0),
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: TextFormField(
                                  controller: _username,
                                  onChanged: _onUsernameChanged,
                                  onTap: _clearError,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Choose a username",
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: Colors.deepOrange),
                                    suffixIcon: usernameSuffix,
                                    border: InputBorder.none,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 16),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // --- Consistent spacing block ---
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: _usernameMessage != null ? 32 : 22,
                          alignment: Alignment.center,
                          child: _usernameMessage != null
                              ? Text(
                            _usernameMessage!,
                            style: GoogleFonts.poppins(
                              color: _usernameAvailable == true
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                        // -------------------------------

                        ValueListenableBuilder<bool>(
                          valueListenable: _showError,
                          builder: (context, visible, _) => AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: visible && _error != null
                                ? Padding(
                              padding:
                              const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        _GradientButton(
                          text: "Continue with Google",
                          onTap: _googleSignup,
                          loading: _loading,
                        ),
                      ],
                      if (mode == AuthMode.login) ...[
                        const SizedBox(height: 40),
                        ValueListenableBuilder<bool>(
                          valueListenable: _showError,
                          builder: (context, visible, _) => AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: visible && _error != null
                                ? Padding(
                              padding:
                              const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        _GradientButton(
                          text: "Continue with Google",
                          onTap: _googleLogin,
                          loading: _loading,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Powered by",
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black54)),
                      Text("FYT LYF",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.deepOrangeAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HEADER (Gradient Border) ---
class _GradientBorderHeader extends StatelessWidget {
  final AuthMode active;
  final Function(AuthMode) onSelect;
  const _GradientBorderHeader({
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFFFF3D00), Color(0xFFFFA726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GradientBorderButton(
          text: "LOGIN",
          selected: active == AuthMode.login,
          gradient: gradient,
          onTap: () => onSelect(AuthMode.login),
        ),
        const SizedBox(width: 20),
        _GradientBorderButton(
          text: "SIGN UP",
          selected: active == AuthMode.signup,
          gradient: gradient,
          onTap: () => onSelect(AuthMode.signup),
        ),
      ],
    );
  }
}

class _GradientBorderButton extends StatelessWidget {
  final String text;
  final bool selected;
  final Gradient gradient;
  final VoidCallback onTap;
  const _GradientBorderButton({
    required this.text,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: selected
            ? Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(2.2),
          child: Container(
            height: 48,
            width: 115,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  gradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        )
            : SizedBox(
          width: 115,
          height: 48,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black87,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Gradient Button ---
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool loading;
  const _GradientButton(
      {required this.text, required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFF3D00), Color(0xFFFFA726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 55,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.3),

              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2)
              : Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}