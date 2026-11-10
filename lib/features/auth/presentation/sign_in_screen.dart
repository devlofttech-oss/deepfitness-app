import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/core/widgets/brand_mark.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sign-in. Phone OTP is the primary route; email and password is the
/// fallback for members whose number has changed or who never had one.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _useEmail = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 6) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    await ref
        .read(authServiceProvider)
        .startPhoneSignIn(
          phoneNumber: phone,
          onCodeSent: (pending) {
            if (!mounted) return;
            setState(() => _busy = false);
            context.push('/verify', extra: pending);
          },
          onFailed: (failure) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _error = failure.message;
            });
          },
          // Android can read the SMS itself, in which case the member is
          // already signed in and the router moves them on.
          onAutoVerified: (_) {
            if (!mounted) return;
            setState(() => _busy = false);
          },
        );
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on RepositoryFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 32),
                  Text(
                    'Sign in',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (_useEmail) ..._emailFields() else ..._phoneFields(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else
                    PrimaryButton(
                      label: _useEmail ? 'Sign in' : 'Send code',
                      onPressed: _useEmail ? _signInWithEmail : _sendCode,
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _useEmail = !_useEmail;
                            _error = null;
                          }),
                    child: Text(
                      _useEmail
                          ? 'Use my phone number instead'
                          : 'Use email and password instead',
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

  List<Widget> _phoneFields() => [
    TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
      ],
      decoration: const InputDecoration(
        labelText: 'Phone number',
        helperText: 'We will text you a six digit code.',
      ),
    ),
  ];

  List<Widget> _emailFields() => [
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(labelText: 'Email'),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _passwordController,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      decoration: const InputDecoration(labelText: 'Password'),
    ),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _busy ? null : _resetPassword,
        child: const Text('Forgot password?'),
      ),
    ),
  ];

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }

    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on RepositoryFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }
}
