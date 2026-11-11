import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'D',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  Text(
                    'DEEP FITNESS',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: Insets.xs),
                  const DfLabel(
                    'Mysore • Athlete Portal',
                    colour: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: Insets.md),
                  Text(
                    _useEmail
                        ? 'Sign in with the email address the gym has on '
                              'file for you.'
                        : 'Enter your registered mobile number to reach '
                              'your workouts and training logs.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  if (_useEmail) ..._emailFields() else ..._phoneFields(),
                  if (_error != null) ...[
                    const SizedBox(height: Insets.md),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: Insets.lg),
                  DfPrimaryButton(
                    label: _useEmail ? 'Sign in' : 'Get verification code',
                    busy: _busy,
                    onPressed: _useEmail ? _signInWithEmail : _sendCode,
                  ),
                  const SizedBox(height: Insets.sm),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _useEmail = !_useEmail;
                              _error = null;
                            }),
                      child: Text(
                        (_useEmail
                                ? 'Sign in with mobile instead'
                                : 'Sign in with member email instead')
                            .toUpperCase(),
                      ),
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
        labelText: 'Mobile number',
        prefixText: '+91  ',
        helperText: 'We will send a 6-digit one-time code by SMS.',
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
