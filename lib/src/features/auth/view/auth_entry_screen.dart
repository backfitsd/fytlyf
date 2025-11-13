// --- AUTH ENTRY (FYT LYF FINAL - ERRORS: VIBRATE + SHAKE + GRADIENT CHECKBOX) ---
// Ready to paste: lib/src/features/auth/view/auth_entry_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback
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
  // mode & input
  AuthMode mode = AuthMode.login;
  final TextEditingController _username = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();

  // backend + state
  bool _loading = false;
  String? _error;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameMessage;
  Timer? _debounce;

  bool _termsAccepted = false;
  bool _termsErrorVisible = false; // toggles visual red highlight

  // firebase typed collections
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore.instance
      .collection('users')
      .withConverter<Map<String, dynamic>>(fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{}, toFirestore: (v, _) => v);
  final CollectionReference<Map<String, dynamic>> _usernames = FirebaseFirestore.instance
      .collection('usernames')
      .withConverter<Map<String, dynamic>>(fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{}, toFirestore: (v, _) => v);

  // animations
  late final AnimationController _gradientCtrl;
  late final AnimationController _headerEntryCtrl;

  // shake controllers for message & terms row
  late final AnimationController _shakeMsgCtrl;
  late final AnimationController _shakeTermsCtrl;

  late final ValueNotifier<bool> _showError;

  static final _usernameReg = RegExp(r'^[a-z0-9._]{4,20}$');

  // constant spacing used equally above & below
  static const double _messageGap = 12.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab == 'signup') mode = AuthMode.signup;

    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _headerEntryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _shakeMsgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _shakeTermsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

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
    _shakeMsgCtrl.dispose();
    _shakeTermsCtrl.dispose();
    _showError.dispose();
    _username.dispose();
    _usernameFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // central error setter — triggers vibration + shake
  void _setError(String? msg) {
    setState(() => _error = msg);
    _showError.value = msg != null && msg.isNotEmpty;
    if (msg != null && msg.isNotEmpty) {
      _vibrate();
      _playShake(_shakeMsgCtrl);
    }
  }

  void _clearError() {
    if (_error != null || _usernameMessage != null || _termsErrorVisible) {
      setState(() {
        _error = null;
        _showError.value = false;
        _usernameMessage = null;
        _termsErrorVisible = false;
      });
    }
  }

  Future<void> _vibrate() async {
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
  }

  void _playShake(AnimationController ctrl) {
    try {
      ctrl.forward(from: 0.0);
    } catch (_) {}
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
    return snap.exists && (snap.data()?.isNotEmpty ?? false);
  }

  Future<bool> _isUsernameFree(String uname) async {
    final snap = await _usernames.doc(uname).get();
    return !snap.exists;
  }

  // ---------------- Username validation (user can type freely) ----------------
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
      // length
      if (value.length < 4) {
        _setValidation("Minimum 4 characters", false);
        return;
      }
      if (value.length > 20) {
        _setValidation("Maximum 20 characters", false);
        return;
      }

      // allowed chars
      if (!RegExp(r'^[a-z0-9._]+$').hasMatch(value)) {
        _setValidation("Only a–z, 0–9, . and _ allowed.", false);
        return;
      }

      // start/end with dot
      if (value.startsWith('.') && value.endsWith('.')) {
        _setValidation("Cannot start and end with .", false);
        return;
      } else if (value.startsWith('.')) {
        _setValidation("Cannot start with .", false);
        return;
      } else if (value.endsWith('.')) {
        _setValidation("Cannot end with .", false);
        return;
      }

      // consecutive / combos
      if (value.contains('..')) {
        _setValidation("Consecutive dots are not allowed.", false);
        return;
      }
      if (value.contains('__')) {
        _setValidation("Consecutive underscores are not allowed.", false);
        return;
      }
      if (value.contains('._') || value.contains('_.')) {
        _setValidation("Input not allowed", false);
        return;
      }

      // counts
      final dotCount = '.'.allMatches(value).length;
      final underscoreCount = '_'.allMatches(value).length;
      if (dotCount > 2) {
        _setValidation("Maximum 2 dots allowed.", false);
        return;
      }
      if (underscoreCount > 2) {
        _setValidation("Maximum 2 underscores allowed.", false);
        return;
      }

      // backend availability
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

    // vibrate + shake message
    _vibrate();
    _playShake(_shakeMsgCtrl);
  }

  // ---------------- Google Login / Signup ----------------
  Future<void> _googleLogin() async {
    _setError(null);
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // ensure chooser
      final google = await googleSignIn.signIn();
      if (google == null) {
        setState(() => _loading = false);
        return;
      }

      final auth = await google.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = cred.user?.uid;

      if (uid == null) {
        _setError('Login failed. Please try again.');
        return;
      }

      final exists = await _userDocExists(uid);

      if (!exists) {
        // if Firestore doc doesn’t exist, send user to signup (not error)
        context.go('/auth/entry', extra: {'initialTab': 'signup'});
        _setError('No account found. Please sign up.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // ✅ Successfully logged in — navigate to dashboard
      if (!mounted) return;
      context.go('/dashboard-root');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' ||
          e.code == 'email-already-in-use') {
        _setError('This email is already registered with another method.');
      } else if (e.code == 'user-disabled') {
        _setError('This user account has been disabled.');
      } else {
        _setError(e.message ?? 'Authentication failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Google login error: $e');
      _setError('Something went wrong. Please check your network and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _googleSignup() async {
    final uname = _username.text.trim().toLowerCase();

    // Terms validation: highlight visually + vibrate + shake
    if (!_termsAccepted) {
      setState(() => _termsErrorVisible = true);
      _vibrate();
      _playShake(_shakeTermsCtrl);
      return;
    } else {
      _termsErrorVisible = false;
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
      if (google == null) {
        setState(() => _loading = false);
        return;
      }
      final auth = await google.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken);

      // try sign-in with credential
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
        txn.set(unameRef, <String, dynamic>{'uid': uid});
        txn.set(_users.doc(uid), <String, dynamic>{
          'uid': uid,
          'email': user.email,
          'name': user.displayName,
          'username': uname,
          'createdAt': FieldValue.serverTimestamp(),
          ..._onboardingToFirestore(),
        });
      });

      if (!mounted) return;
      context.go('/dashboard-root');
    } on FirebaseAuthException catch (e) {
      // handle cases where email already in use or account exists with different credential
      if (e.code == 'account-exists-with-different-credential' || e.code == 'email-already-in-use') {
        _setError('This email is already registered. Please login or use the original sign-in method.');
      } else if (e.code == 'invalid-credential') {
        _setError('Invalid credentials provided. Please try again.');
      } else {
        _setError(e.message ?? 'Authentication failed. Please try again.');
      }
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final gradientHeight = screenH * 0.35;
    final cardWidth = screenW * 0.92;

    Widget? usernameSuffixLocal;
    if (_checkingUsername) {
      usernameSuffixLocal = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF9E9E9E)),
      );
    } else if (_usernameAvailable == true) {
      usernameSuffixLocal = const Icon(Icons.check_circle, color: Colors.green, size: 22);
    } else if (_usernameAvailable == false) {
      usernameSuffixLocal = const Icon(Icons.cancel, color: Colors.redAccent, size: 22);
    }

    // shake transforms
    Widget buildShake({required AnimationController ctrl, required Widget child}) {
      return AnimatedBuilder(
        animation: ctrl,
        builder: (c, w) {
          // produce a small left-right sequence using a sinus curve
          final t = ctrl.value;
          final dx = math.sin(t * math.pi * 4) * 8.0 * (1 - t); // decaying
          return Transform.translate(offset: Offset(dx, 0), child: w);
        },
        child: child,
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _clearError();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey.shade50,
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
                      child: Column(
                        children: [
                          const SizedBox(height: 65),
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
                          ? buildShake(
                        ctrl: _shakeMsgCtrl,
                        child: _SignupCardV2(
                          key: const ValueKey('signupCard'),
                          usernameController: _username,
                          usernameFocus: _usernameFocus,
                          usernameSuffix: usernameSuffixLocal,
                          checkingUsername: _checkingUsername,
                          usernameAvailable: _usernameAvailable,
                          usernameMessage: _usernameMessage,
                          onUsernameChanged: _onUsernameChanged,
                          onClearError: _clearError,
                          termsAccepted: _termsAccepted,
                          termsErrorVisible: _termsErrorVisible,
                          onTermsChanged: (v) => setState(() {
                            _termsAccepted = v ?? false;
                            _termsErrorVisible = false;
                          }),
                          onTermsOpen: () => _showTermsDialog(context),
                          onGoogleSignup: () {
                            // if terms missing — we shake terms specifically
                            if (!_termsAccepted) {
                              setState(() => _termsErrorVisible = true);
                              _vibrate();
                              _playShake(_shakeTermsCtrl);
                              return;
                            }
                            _googleSignup();
                          },
                          loading: _loading,
                          messageGap: _messageGap,
                          shakeTermsCtrl: _shakeTermsCtrl,
                          // NEW: pass error + notifier + shake controller so signup shows errors
                          error: _error,
                          showError: _showError,
                          shakeMsgCtrl: _shakeMsgCtrl,
                        ),
                      )
                          : _LoginCardV2(
                        key: const ValueKey('loginCard'),
                        onGoogleLogin: () => _googleLogin(),
                        loading: _loading,
                        error: _error,
                        showError: _showError,
                        messageGap: _messageGap,
                        shakeMsgCtrl: _shakeMsgCtrl,
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

  // Terms dialog unchanged
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

// ---------------- Components ----------------

// Capsule Header (unchanged visually)
class _CapsuleHeader extends StatelessWidget {
  final AuthMode mode;
  final Function(AuthMode) onSelect;
  const _CapsuleHeader({required this.mode, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;
    final width = MediaQuery.of(context).size.width;
    final capsuleWidth = width * 0.72;

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
          GestureDetector(onTap: () => onSelect(AuthMode.login), child: _tab("LOGIN", isLogin)),
          GestureDetector(onTap: () => onSelect(AuthMode.signup), child: _tab("SIGN UP", !isLogin)),
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
        gradient: active ? const LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: active ? null : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(active ? 0.0 : 0.6), width: active ? 0 : 1.0),
      ),
      alignment: Alignment.center,
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontWeight: active ? FontWeight.w800 : FontWeight.w600, fontSize: 15)),
    );
  }
}

// --- Signup Card variant with gradient checkbox + equal gaps + shake hook ---
// UPDATED: error always shown below username field
class _SignupCardV2 extends StatelessWidget {
  final TextEditingController usernameController;
  final FocusNode usernameFocus;
  final Widget? usernameSuffix;
  final bool checkingUsername;
  final bool? usernameAvailable;
  final String? usernameMessage;
  final Function(String) onUsernameChanged;
  final VoidCallback onClearError;
  final bool termsAccepted;
  final bool termsErrorVisible;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTermsOpen;
  final VoidCallback onGoogleSignup;
  final bool loading;
  final double messageGap;
  final AnimationController shakeTermsCtrl;

  // NEW: error display props
  final String? error;
  final ValueNotifier<bool> showError;
  final AnimationController shakeMsgCtrl;

  const _SignupCardV2({
    Key? key,
    required this.usernameController,
    required this.usernameFocus,
    required this.usernameSuffix,
    required this.checkingUsername,
    required this.usernameAvailable,
    required this.usernameMessage,
    required this.onUsernameChanged,
    required this.onClearError,
    required this.termsAccepted,
    required this.termsErrorVisible,
    required this.onTermsChanged,
    required this.onTermsOpen,
    required this.onGoogleSignup,
    required this.loading,
    required this.messageGap,
    required this.shakeTermsCtrl,
    required this.error,
    required this.showError,
    required this.shakeMsgCtrl,
  }) : super(key: key);

  Widget _buildCheckbox(BuildContext ctx) {
    // gradient when checked, red border when termsErrorVisible true
    final gradient = const LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    return GestureDetector(
      onTap: () => onTermsChanged(!termsAccepted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          gradient: termsAccepted ? gradient : null,
          color: termsAccepted ? null : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: termsErrorVisible ? Colors.redAccent : (termsAccepted ? Colors.transparent : Colors.grey.shade400), width: 1.6),
          boxShadow: termsAccepted ? [BoxShadow(color: Colors.orange.withOpacity(0.14), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: termsAccepted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = usernameFocus.hasFocus;
    final textStyle = termsErrorVisible ? GoogleFonts.poppins(color: Colors.redAccent) : GoogleFonts.poppins(color: Colors.black87);

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: focused ? [BoxShadow(color: Colors.orange.withOpacity(0.12), blurRadius: 14, spreadRadius: 1)] : null,
            border: Border.all(color: Colors.deepOrange, width: 1.0),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: TextFormField(
              controller: usernameController,
              focusNode: usernameFocus,
              onChanged: (v) {
                onUsernameChanged(v);
              },
              onTap: onClearError,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Choose a username",
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
                suffixIcon: usernameSuffix,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              ),
            ),
          ),
        ),

        SizedBox(height: messageGap * 0.8),

        // --- Combined message area: usernameMessage OR general _error (always below username) ---
        AnimatedBuilder(
          animation: shakeMsgCtrl,
          builder: (c, w) {
            final t = shakeMsgCtrl.value;
            final dx = math.sin(t * math.pi * 4) * 8.0 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: w);
          },
          child: ValueListenableBuilder<bool>(
            valueListenable: showError,
            builder: (context, visible, _) {
              String? displayMessage = error ?? usernameMessage;
              Color msgColor = Colors.redAccent;

              if (usernameMessage != null && usernameAvailable == true && error == null) {
                msgColor = Colors.green;
              }

              // Show if either usernameMessage present OR error visible+not null
              final show = (usernameMessage != null) || (visible && error != null);

              return AnimatedOpacity(
                opacity: show ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: show
                    ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    displayMessage ?? '',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      color: msgColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ),

        SizedBox(height: messageGap),

        // Terms row with shake wrapper
        AnimatedBuilder(
          animation: shakeTermsCtrl,
          builder: (c, w) {
            final t = shakeTermsCtrl.value;
            final dx = math.sin(t * math.pi * 4) * 8.0 * (1 - t);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: w,
            );
          },
          child: Row(
            children: [
              _buildCheckbox(context),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onTermsOpen,
                  child: RichText(
                    text: TextSpan(
                      text: "I agree to the ",
                      style: textStyle.copyWith(fontSize: 13),
                      children: [
                        TextSpan(text: "Terms & Conditions", style: textStyle.copyWith(color: termsErrorVisible ? Colors.redAccent : Colors.deepOrange, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // If termsErrorVisible -> do not show extra text; border & text made red above
        SizedBox(height: messageGap),

        Center(child: _GradientButton(text: "Continue with Google", onTap: onGoogleSignup, loading: loading)),

        const SizedBox(height: 8),
      ]),
    );
  }
}

// --- Login Card variant that keeps continue button in same place (no move) and shows errors left with shake+vibrate
class _LoginCardV2 extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final bool loading;
  final String? error;
  final ValueNotifier<bool> showError;
  final double messageGap;
  final AnimationController shakeMsgCtrl;

  const _LoginCardV2({Key? key, required this.onGoogleLogin, required this.loading, required this.error, required this.showError, required this.messageGap, required this.shakeMsgCtrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // keep button at same vertical position: wrap in Column with fixed spacing
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: _GradientButton(text: "Continue with Google", onTap: onGoogleLogin, loading: loading)),
        SizedBox(height: messageGap),
        // error area — Animated + shake wrapper
        AnimatedBuilder(
          animation: shakeMsgCtrl,
          builder: (c, w) {
            final t = shakeMsgCtrl.value;
            final dx = math.sin(t * math.pi * 4) * 8.0 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: w);
          },
          child: ValueListenableBuilder<bool>(
            valueListenable: showError,
            builder: (context, visible, _) => AnimatedOpacity(
              opacity: visible && error != null ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: visible && error != null
                  ? Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  error!,
                  style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.left,
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ]),
    );
  }
}

// Gradient Button (unchanged)
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool loading;
  const _GradientButton({Key? key, required this.text, required this.onTap, required this.loading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(colors: [Color(0xFFFF3D00), Color(0xFFFF6D00), Color(0xFFFFA726)], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.78,
        height: 54,
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Center(child: loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text(text, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
      ),
    );
  }
}