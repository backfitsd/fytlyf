import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailCtl = TextEditingController();
  bool sent = false;

  Future<void> _reset() async {
    if (!emailCtl.text.contains('@')) return;
    await ref.read(authServiceProvider).resetPassword(emailCtl.text.trim());
    setState(() => sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: sent
              ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.email_outlined, size: 64),
            const SizedBox(height: 16),
            Text('Password reset link sent to ${emailCtl.text}'),
            TextButton(onPressed: () => context.pop(), child: const Text('Back to login'))
          ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reset, child: const Text('Send reset link')),
          ]),
        ),
      ),
    );
  }
}
