import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_button.dart';
import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty) {
      return;
    }

    if (password.text != confirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => loading = true);

    final error = await ref
        .read(authStateProvider.notifier)
        .register(
          name.text.trim(),
          email.text.trim(),
          password.text,
          confirm.text,
        );

    if (!mounted) return;

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create your account',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Join the community and share your ideas.',
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Create account',
                  onPressed: submit,
                  loading: loading,
                  icon: Icons.person_add_alt_1_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
