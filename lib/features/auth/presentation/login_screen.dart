import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/auth/data/auth_repository.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:deepfitness/core/widgets/async_state.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Phone is the primary sign-in method, per the developer guide; email and
/// password are the fallback for members who have no number on file.
enum _SignInMethod { phone, email }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  _SignInMethod _method = _SignInMethod.phone;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final verification = ref.watch(phoneVerificationProvider);

    return _AuthScaffold(
      title: 'Welcome Back',
      error: _authError(authState),
      isBackendConfigured: authState.value?.isBackendConfigured,
      children: [
        SegmentedButton<_SignInMethod>(
          segments: const [
            ButtonSegment(
              value: _SignInMethod.phone,
              label: Text('Phone'),
              icon: Icon(Icons.sms_outlined),
            ),
            ButtonSegment(
              value: _SignInMethod.email,
              label: Text('Email'),
              icon: Icon(Icons.alternate_email_rounded),
            ),
          ],
          selected: {_method},
          onSelectionChanged: isLoading
              ? null
              : (selection) {
                  // Leaving the phone flow abandons any code in flight, so the
                  // member is not left on a stale verification id.
                  ref.read(phoneVerificationProvider.notifier).clear();
                  _codeController.clear();
                  setState(() => _method = selection.first);
                },
        ),
        const SizedBox(height: 24),
        if (_method == _SignInMethod.phone)
          ..._phoneFields(context, isLoading, verification)
        else
          ..._emailFields(context, isLoading),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : () => context.push('/register'),
            child: const Text('Create member account'),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: isLoading ? null : () => context.push('/trainer-login'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Are you a trainer? Log in'),
          ),
        ),
      ],
    );
  }

  List<Widget> _phoneFields(
    BuildContext context,
    bool isLoading,
    PhoneVerification? verification,
  ) {
    final codeSent = verification != null;

    return [
      const _FieldLabel('Mobile Number'),
      TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        enabled: !codeSent && !isLoading,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: '98765 43210',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
      ),
      if (codeSent) ...[
        const SizedBox(height: 20),
        const _FieldLabel('Six-digit code'),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '______',
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined),
            helperText: 'Sent to ${verification.phoneNumber}',
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: isLoading ? 'Checking...' : 'Verify and Log In',
          onPressed: isLoading ? null : () => _confirmOtp(context),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    ref.read(phoneVerificationProvider.notifier).clear();
                    _codeController.clear();
                  },
            child: const Text('Use a different number'),
          ),
        ),
      ] else ...[
        const SizedBox(height: 20),
        PrimaryButton(
          label: isLoading ? 'Sending...' : 'Send Code',
          icon: Icons.arrow_forward_rounded,
          onPressed: isLoading ? null : () => _sendOtp(context),
        ),
      ],
    ];
  }

  List<Widget> _emailFields(BuildContext context, bool isLoading) {
    return [
      _CredentialFields(
        identifierController: _identifierController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        onTogglePassword: () =>
            setState(() => _obscurePassword = !_obscurePassword),
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _resetPassword(context),
          child: const Text('Forgot Password?'),
        ),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: isLoading ? 'Signing In...' : 'Log In',
        onPressed: isLoading ? null : () => _signIn(context),
      ),
    ];
  }

  Future<void> _sendOtp(BuildContext context) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack(context, 'Enter your mobile number.');
      return;
    }
    await ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  Future<void> _confirmOtp(BuildContext context) async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showSnack(context, 'Enter the six-digit code.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .confirmOtp(smsCode: code, expectedRole: UserRole.member);

    if (success && context.mounted) {
      context.go('/');
    }
  }

  Future<void> _signIn(BuildContext context) async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showSnack(context, 'Enter login and password.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: identifier,
          password: password,
          expectedRole: UserRole.member,
        );

    if (success && context.mounted) {
      context.go('/');
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    await _requestPasswordReset(context, ref, _identifierController.text);
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return _AuthScaffold(
      title: 'Create Account',
      subtitle: 'Start tracking your workouts, meals, and progress',
      error: _authError(authState),
      isBackendConfigured: authState.value?.isBackendConfigured,
      children: [
        const _FieldLabel('Full Name'),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Your name',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 20),
        _CredentialFields(
          identifierController: _identifierController,
          passwordController: _passwordController,
          obscurePassword: _obscurePassword,
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: isLoading ? 'Creating...' : 'Create Account',
          onPressed: isLoading ? null : () => _register(context),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : () => context.go('/login'),
            child: const Text('Already have an account? Log in'),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: isLoading ? null : () => context.push('/trainer-login'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Are you a trainer? Log in'),
          ),
        ),
      ],
    );
  }

  Future<void> _register(BuildContext context) async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || identifier.isEmpty || password.length < 6) {
      _showSnack(context, 'Enter name, login, and 6+ character password.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .createMemberAccount(
          name: name,
          identifier: identifier,
          password: password,
        );

    if (success && context.mounted) {
      context.go('/');
    }
  }
}

class TrainerLoginScreen extends ConsumerStatefulWidget {
  const TrainerLoginScreen({super.key});

  @override
  ConsumerState<TrainerLoginScreen> createState() => _TrainerLoginScreenState();
}

class _TrainerLoginScreenState extends ConsumerState<TrainerLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return _AuthScaffold(
      title: 'Trainer Login',
      subtitle: 'Use your existing trainer account',
      error: _authError(authState),
      isBackendConfigured: authState.value?.isBackendConfigured,
      children: [
        _CredentialFields(
          identifierController: _identifierController,
          passwordController: _passwordController,
          obscurePassword: _obscurePassword,
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _resetPassword(context),
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: isLoading ? 'Signing In...' : 'Log In as Trainer',
          onPressed: isLoading ? null : () => _signIn(context),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : () => context.go('/login'),
            child: const Text('Member login'),
          ),
        ),
      ],
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showSnack(context, 'Enter trainer login and password.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          identifier: identifier,
          password: password,
          expectedRole: UserRole.trainer,
        );

    if (success && context.mounted) {
      context.go('/trainer');
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    await _requestPasswordReset(context, ref, _identifierController.text);
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.error,
    this.isBackendConfigured,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? error;
  final bool? isBackendConfigured;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _AuthBackgroundPainter()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AuthHeader(),
                  const SizedBox(height: 34),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  if (isBackendConfigured == false) ...[
                    const _AuthError('Firebase is not configured.'),
                    const SizedBox(height: 14),
                  ],
                  if (error != null) ...[
                    _AuthError(error!),
                    const SizedBox(height: 14),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/logo2.png',
            width: 92,
            height: 92,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
              children: const [
                TextSpan(
                  text: 'DEEP ',
                  style: TextStyle(color: AppColors.white),
                ),
                TextSpan(
                  text: 'FITNESS',
                  style: TextStyle(color: AppColors.goldBright),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  const _AuthBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.goldBright.withValues(alpha: .10),
              AppColors.night.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .50, size.height * .18),
              radius: size.width * .55,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * .50, size.height * .18),
      size.width * .55,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CredentialFields extends StatelessWidget {
  const _CredentialFields({
    required this.identifierController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Email or Phone'),
        TextField(
          controller: identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Enter your Email or Phone',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Password'),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.danger,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

String? _authError(AsyncValue<AuthSessionState> authState) {
  if (!authState.hasError) return null;
  return friendlyErrorMessage(authState.error!);
}

Future<void> _requestPasswordReset(
  BuildContext context,
  WidgetRef ref,
  String identifier,
) async {
  final email = identifier.trim();
  if (email.isEmpty || !email.contains('@')) {
    _showSnack(context, 'Enter your email first.');
    return;
  }

  try {
    await ref.read(authControllerProvider.notifier).resetPassword(email);
    if (context.mounted) {
      _showSnack(context, 'Password reset email requested.');
    }
  } catch (error) {
    if (context.mounted) _showSnack(context, friendlyErrorMessage(error));
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
