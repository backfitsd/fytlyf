// --- AUTH ENTRY (FYT LYF FINAL - STATIC LOGIN + ANIMATED SIGNUP) ---
// Fully functional backend + fixed layout, adaptive to all screen sizes.

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

class _AuthEntryScreenState extends State<AuthEntryScreen> with TickerProviderStateMixin {
  AuthMode mode = AuthMode.login;
  final TextEditingController _username = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();

  bool _loading = false;
  String? _error;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameMessage;
  Timer? _debounce;

  bool _termsAccepted = false;
  String? _termsError;

  final _users = FirebaseFirestore.instance.collection('users');
  final _usernames = FirebaseFirestore.instance.collection('usernames');

  late final AnimationController _gradientCtrl;
  late final AnimationController _headerEntryCtrl;
  late final ValueNotifier<bool> _showError;

  static final _usernameReg = RegExp(r'^[a-z0-9._]{4,20}$');

  @override
  void initState() {
    super.initState();
    if (widget.initialTab == 'signup') mode = AuthMode.signup;

    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _headerEntryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _showError = ValueNotifier(false);

    _usernameFocus.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerEntryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _headerEntryCtrl.dispose();
    _showError.dispose();
    _username.dispose();
    _usernameFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _clearError() {
    if (_error != null || _usernameMessage != null || _termsError != null) {
      setState(() {
        _error = null;
        _showError.value = false;
        _usernameMessage = null;
        _termsError = null;
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

  // Username validation logic
  void _onUsernameChanged(String raw) {
    String value = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (_username.text != value) {
      _username.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
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

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (value.length < 4) return _setValidation("Minimum 4 characters", false);
      if (value.length > 20) return _setValidation("Maximum 20 characters", false);
      if (!RegExp(r'^[a-z0-9._]+$').hasMatch(value)) return _setValidation("Only a–z, 0–9, . and _ allowed.", false);
      if (value.startsWith('.') && value.endsWith('.')) return _setValidation("Cannot start and end with .", false);
      if (value.startsWith('.')) return _setValidation("Cannot start with .", false);
      if (value.endsWith('.')) return _setValidation("Cannot end with .", false);
      if (value.contains('..')) return _setValidation("Consecutive dots are not allowed.", false);
      if (value.contains('__')) return _setValidation("Consecutive underscores are not allowed.", false);
      if (value.contains('._') || value.contains('_.')) return _setValidation("Input not allowed", false);
      if ('.'.allMatches(value).length > 2) return _setValidation("Maximum 2 dots allowed.", false);
      if ('_'.allMatches(value).length > 2) return _setValidation("Maximum 2 underscores allowed.", false);

      try {
        final free = await _isUsernameFree(value);
        if (!mounted) return;
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = free;
          _usernameMessage = free ? "Username available" : "Username not available";
        });
      } catch (_) {
        if (!mounted) return;
        _setValidation("Couldn't check username. Try again.", false);
      }
    });
  }

  void _setValidation(String msg, bool available) {
    if (!mounted) return;
    setState(() {
      _checkingUsername = false;
      _usernameAvailable = available;
      _usernameMessage = msg;
    });
  }

  // Google Login
  Future<void> _googleLogin() async {
    _setError(null);
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final google = await googleSignIn.signIn();
      if (google == null) return setState(() => _loading = false);
      final auth = await google.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken);
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

  // Google Signup
  Future<void> _googleSignup() async {
    final uname = _username.text.trim().toLowerCase();
    if (!_termsAccepted) {
      setState(() => _termsError = 'Please accept Terms & Conditions');
      return;
    } else {
      _termsError = null;
    }
    if (!_usernameReg.hasMatch(uname) || _usernameAvailable != true) {
      _setError('Enter a valid and available username.');
      return;
    }
    if (!_hasAllOnboardingData()) {
      if (!mounted) return;
      context.go('/onboarding/gender');
      return;
    }

    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final google = await googleSignIn.signIn();
      if (google == null) return setState(() => _loading = false);
      final auth = await google.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken);
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

  // UI
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final gradientHeight = screenH * 0.35;
    final cardWidth = screenW * 0.9;

    Widget? usernameSuffix;
    if (_checkingUsername) {
<<<<<<< HEAD
      _usernameSuffix = const SizedBox(
=======
      usernameSuffix = SizedBox(
>>>>>>> 065980a7c479c2d4d399547d5fc0e0eb99f64f7f
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF9E9E9E)),
      );
    } else if (_usernameAvailable == true) {
<<<<<<< HEAD
      _usernameSuffix = const Icon(Icons.check_circle, color: Colors.green, size: 22);
    } else if (_usernameAvailable == false) {
      _usernameSuffix = const Icon(Icons.cancel, color: Colors.redAccent, size: 22);
=======
      usernameSuffix =
      const Icon(Icons.check_circle, color: Colors.green, size: 25);
    } else if (_usernameAvailable == false) {
      usernameSuffix =
      const Icon(Icons.cancel, color: Colors.red, size: 25);
>>>>>>> 065980a7c479c2d4d399547d5fc0e0eb99f64f7f
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _clearError();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                // --- Gradient Header ---
                SizedBox(
                  height: gradientHeight,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _headerEntryCtrl,
                    builder: (context, child) {
                      final t = Curves.easeOut.transform(_headerEntryCtrl.value);
                      return Transform.translate(offset: Offset(0, 30 * (1 - t)), child: Opacity(opacity: t, child: child));
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00), Color(0xFFFFA726)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                      ),
<<<<<<< HEAD
                      child: Column(
                        children: [
                          const SizedBox(height: 75),
                          Text("FYT LYF", style: GoogleFonts.pottaOne(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("FEEL YOUR TRANSFORMATION", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                          Text("LOVE YOUR FITNESS", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CapsuleHeader(
                              mode: mode,
                              onSelect: (m) {
                                _clearError();
                                setState(() => mode = m);
                              },
=======
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
>>>>>>> 065980a7c479c2d4d399547d5fc0e0eb99f64f7f
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // --- Card area ---
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: SizedBox(
                      width: cardWidth,
                      child: mode == AuthMode.signup
                          ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeInOutCubicEmphasized,
                        switchOutCurve: Curves.easeInOutCubicEmphasized,
                        child: _SignupCard(
                          key: const ValueKey('signupCard'),
                          usernameController: _username,
                          usernameFocus: _usernameFocus,
                          usernameSuffix: _usernameSuffix,
                          checkingUsername: _checkingUsername,
                          usernameAvailable: _usernameAvailable,
                          usernameMessage: _usernameMessage,
                          onUsernameChanged: _onUsernameChanged,
                          onClearError: _clearError,
                          termsAccepted: _termsAccepted,
                          termsError: _termsError,
                          onTermsChanged: (v) => setState(() {
                            _termsAccepted = v ?? false;
                            _termsError = null;
                          }),
                          onTermsOpen: () => _showTermsDialog(context),
                          onGoogleSignup: _googleSignup,
                          loading: _loading,
                        ),
                      )
                          : _LoginCard(
                        key: const ValueKey('loginCard'),
                        onGoogleLogin: _googleLogin,
                        loading: _loading,
                        error: _error,
                        showError: _showError,
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),

            // --- Footer ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 35,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Powered by", style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
                  Text("FYT LYF", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.deepOrangeAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Terms dialog
  void _showTermsDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dCtx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Column(
            children: [
              Container(
                height: 60,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                alignment: Alignment.center,
                child: Text("Terms & Conditions", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Text(
                    "These are the Terms & Conditions for FYT LYF.\n\n1. You agree to use the app responsibly.\n2. We respect your privacy.\n3. No misuse or data scraping.\n4. FYT LYF may update these terms.",
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.pop(dCtx),
                      child: Text("Agree", style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.pop(dCtx),
                      child: Text("Close", style: GoogleFonts.poppins(color: Colors.black87)),
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
}

// Capsule Header
class _CapsuleHeader extends StatelessWidget {
  final AuthMode mode;
  final Function(AuthMode) onSelect;
  const _CapsuleHeader({required this.mode, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;
    final width = MediaQuery.of(context).size.width;
    final capsuleWidth = width * 0.72;
    final tabWidth = capsuleWidth * 0.48;

    return Container(
      width: capsuleWidth,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => onSelect(AuthMode.login),
            child: _tab("LOGIN", isLogin),
          ),
          GestureDetector(
            onTap: () => onSelect(AuthMode.signup),
            child: _tab("SIGN UP", !isLogin),
          ),
        ],
      ),
    );
  }

  Widget _tab(String text, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      width: 130,
      height: 44,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: active ? null : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(active ? 0.0 : 0.6), width: active ? 0 : 1.0),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

// Signup Card
class _SignupCard extends StatelessWidget {
  final TextEditingController usernameController;
  final FocusNode usernameFocus;
  final Widget? usernameSuffix;
  final bool checkingUsername;
  final bool? usernameAvailable;
  final String? usernameMessage;
  final Function(String) onUsernameChanged;
  final VoidCallback onClearError;
  final bool termsAccepted;
  final String? termsError;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTermsOpen;
  final VoidCallback onGoogleSignup;
  final bool loading;

  const _SignupCard({
    required Key key,
    required this.usernameController,
    required this.usernameFocus,
    required this.usernameSuffix,
    required this.checkingUsername,
    required this.usernameAvailable,
    required this.usernameMessage,
    required this.onUsernameChanged,
    required this.onClearError,
    required this.termsAccepted,
    required this.termsError,
    required this.onTermsChanged,
    required this.onTermsOpen,
    required this.onGoogleSignup,
    required this.loading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: usernameController,
            focusNode: usernameFocus,
            onChanged: onUsernameChanged,
            onTap: onClearError,
            decoration: InputDecoration(
              hintText: "Choose a username",
              prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
              suffixIcon: usernameSuffix,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            ),
          ),
          const SizedBox(height: 8),
          if (usernameMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                usernameMessage!,
                style: GoogleFonts.poppins(
                  color: usernameAvailable == true ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          Row(
            children: [
              Checkbox(value: termsAccepted, onChanged: onTermsChanged),
              Expanded(
                child: GestureDetector(
                  onTap: onTermsOpen,
                  child: RichText(
                    text: TextSpan(
                      text: "I agree to the ",
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
                      children: [
                        TextSpan(
                          text: "Terms & Conditions",
                          style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (termsError != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Text(termsError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13)),
            ),
          const SizedBox(height: 12),
          Center(child: _GradientButton(text: "Continue with Google", onTap: onGoogleSignup, loading: loading)),
        ],
      ),
    );
  }
}

// Login Card
class _LoginCard extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final bool loading;
  final String? error;
  final ValueNotifier<bool> showError;

  const _LoginCard({required Key key, required this.onGoogleLogin, required this.loading, required this.error, required this.showError}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _GradientButton(text: "Continue with Google", onTap: onGoogleLogin, loading: loading)),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: showError,
            builder: (context, visible, _) => AnimatedOpacity(
              opacity: visible && error != null ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: visible && error != null
                  ? Padding(padding: const EdgeInsets.only(left: 8, top: 4), child: Text(error!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13)))
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// Gradient Button
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool loading;
  const _GradientButton({required this.text, required this.onTap, required this.loading, super.key});

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00), Color(0xFFFFA726)], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
<<<<<<< HEAD
        width: MediaQuery.of(context).size.width * 0.78,
        height: 54,
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Center(child: loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text(text, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
=======
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
>>>>>>> 065980a7c479c2d4d399547d5fc0e0eb99f64f7f
      ),
    );
  }
}
