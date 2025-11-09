import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class SignupForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitch;
  const SignupForm({super.key, required this.onSwitch});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final nameCtl = TextEditingController();
  final userCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  final referralCtl = TextEditingController();
  bool termsAccepted = false;
  bool usernameAvailable = true;
  bool checkingUsername = false;

  @override
  void dispose() {
    nameCtl.dispose();
    userCtl.dispose();
    emailCtl.dispose();
    passCtl.dispose();
    confirmCtl.dispose();
    referralCtl.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final u = userCtl.text.trim();
    if (u.isEmpty) return;
    setState(() => checkingUsername = true);
    try {
      final available = await ref.read(usernameServiceProvider).checkAvailability(u);
      setState(() => usernameAvailable = available);
    } catch (_) {
      setState(() => usernameAvailable = false);
    } finally {
      setState(() => checkingUsername = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept Terms & Privacy')));
      return;
    }
    if (!usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username not available')));
      return;
    }
    ref.read(authErrorProvider.notifier).state = null;
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      await ref.read(usernameServiceProvider).reserve(userCtl.text.trim());
      final auth = ref.read(authServiceProvider);
      final cred = await auth.createAccount(emailCtl.text.trim(), passCtl.text);
      await auth.sendEmailVerification(cred.user!);
      // After create + verification, move to verify screen or dashboard depending on flow
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Create Account', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextFormField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v != null && v.length >= 3 && v.length <= 15 ? null : '3–15 letters'),
          const SizedBox(height: 12),
          TextFormField(
            controller: userCtl,
            decoration: InputDecoration(
              labelText: 'Username',
              suffixIcon: checkingUsername ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(usernameAvailable ? Icons.check_circle : Icons.cancel, color: usernameAvailable ? Colors.green : Colors.red),
            ),
            onChanged: (_) => _checkUsername(),
            validator: (v) {
              final r = RegExp(r'^[a-zA-Z0-9._]{4,20}$');
              if (v == null || !r.hasMatch(v)) return 'Invalid username';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v != null && v.contains('@') ? null : 'Invalid email'),
          const SizedBox(height: 12),
          TextFormField(controller: passCtl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v != null && v.length >= 8 ? null : 'At least 8 characters'),
          const SizedBox(height: 12),
          TextFormField(controller: confirmCtl, decoration: const InputDecoration(labelText: 'Verify password'), obscureText: true, validator: (v) => v == passCtl.text ? null : 'Passwords do not match'),
          const SizedBox(height: 12),
          TextFormField(controller: referralCtl, decoration: const InputDecoration(labelText: 'Referral code (optional)')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error, style: const TextStyle(color: Colors.red))),
          Row(children: [
            Checkbox(value: termsAccepted, onChanged: (v) => setState(() => termsAccepted = v ?? false)),
            const Expanded(child: Text('I agree to the Terms of Service & Privacy Policy'))
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: loading ? null : _signup, child: loading ? const CircularProgressIndicator.adaptive() : const Text('Create Account'))),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Already have an account?'), TextButton(onPressed: widget.onSwitch, child: const Text('Log in'))]),
        ]),
      ),
    );
  }
}
