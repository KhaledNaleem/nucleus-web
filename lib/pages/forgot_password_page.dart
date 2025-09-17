import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  static const routeName = '/forgot';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _sending = false;
  String? _msg;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _msg = null;
      _err = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      setState(() => _msg = 'Reset email sent. Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      setState(() => _err = e.message ?? 'Failed to send reset email.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Forgot Password', style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Send reset link'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_msg != null) Text(_msg!, style: const TextStyle(color: Colors.greenAccent)),
                  if (_err != null) Text(_err!, style: TextStyle(color: theme.colorScheme.error)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back'))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
