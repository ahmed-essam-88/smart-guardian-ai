import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../widgets/gradient_card.dart';

/// Email/password sign-in and sign-up with Firebase Auth.
class LoginScreen extends StatefulWidget {
  final AuthApi auth;
  final String? language;
  final ValueChanged<String>? onLanguage;
  const LoginScreen(
      {super.key, required this.auth, this.language, this.onLanguage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (!_validEmail(email)) {
      setState(() => _error = 'The email address is not valid.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_signUp) {
        await widget.auth.signUp(email, pass);
      } else {
        await widget.auth.signIn(email, pass);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      setState(() => _error = 'Enter your email first, then tap reset.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.auth.sendPasswordReset(email);
      if (mounted) {
        setState(() => _info =
            'Password reset email sent. Check your inbox and spam folder.');
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: tr(context, hint),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onLanguage != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                            visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(
                              value: 'ar', label: m.Text('العربية')),
                          ButtonSegment(
                              value: 'en', label: m.Text('English')),
                        ],
                        selected: {widget.language ?? 'en'},
                        onSelectionChanged: (v) =>
                            widget.onLanguage!(v.first),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Icon(Icons.shield_outlined,
                      size: 56, color: AppColors.cyan),
                  const SizedBox(height: 10),
                  const Text('SMART GUARDIAN AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 2)),
                  const SizedBox(height: 20),
                  GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_signUp ? 'Create account' : 'Sign in',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textDirection: TextDirection.ltr,
                          decoration: _dec('Email', Icons.email_outlined),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _password,
                          obscureText: _hidePassword,
                          textDirection: TextDirection.ltr,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _busy ? null : _submit(),
                          decoration: _dec('Password', Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                              )),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.critical, fontSize: 12.5)),
                        ],
                        if (_info != null) ...[
                          const SizedBox(height: 10),
                          Text(_info!,
                              style: const TextStyle(
                                  color: AppColors.safe, fontSize: 12.5)),
                        ],
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(_signUp ? 'Create account' : 'Sign in'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _signUp = !_signUp;
                                    _error = null;
                                    _info = null;
                                  }),
                          child: Text(_signUp
                              ? 'I already have an account'
                              : 'Create a new account'),
                        ),
                        if (!_signUp)
                          TextButton(
                            onPressed: _busy ? null : _reset,
                            child: const Text('Forgot password?'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
