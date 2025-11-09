import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitch;
  const LoginForm({super.key, required this.onSwitch});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();

  @override
  void dispose() {
    emailCtl.dispose();
    passCtl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authErrorProvider.notifier).state = null;
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).signIn(emailCtl.text.trim(), passCtl.text.trim());
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
          Text('Log In', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextFormField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email'),
          const SizedBox(height: 12),
          TextFormField(controller: passCtl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 chars'),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: loading ? null : _login, child: loading ? const CircularProgressIndicator.adaptive() : const Text('Log In'))),
          TextButton(onPressed: widget.onSwitch, child: const Text('Create account'))
        ]),
      ),
    );
  }
}
