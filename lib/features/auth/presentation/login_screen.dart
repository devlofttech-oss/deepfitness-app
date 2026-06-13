import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/brand_mark.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
      title: 'Welcome Back',
      subtitle: 'Log in to continue your fitness journey',
      error: _authError(authState),
      isSupabaseConfigured: authState.value?.isSupabaseConfigured,
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
          label: isLoading ? 'Signing In...' : 'Log In',
          onPressed: isLoading ? () {} : () => _signIn(context),
        ),
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

  Future<void> _signIn(BuildContext context) async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showSnack(context, 'Enter login and password.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          identifier: identifier,
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
      isSupabaseConfigured: authState.value?.isSupabaseConfigured,
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
          onPressed: isLoading ? () {} : () => _register(context),
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
      isSupabaseConfigured: authState.value?.isSupabaseConfigured,
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
          onPressed: isLoading ? () {} : () => _signIn(context),
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
    required this.subtitle,
    required this.children,
    this.error,
    this.isSupabaseConfigured,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? error;
  final bool? isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AuthHeader(),
              const SizedBox(height: 46),
              Text(
                title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 30),
              if (isSupabaseConfigured == false) ...[
                const _AuthError('Supabase is not configured.'),
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
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(child: BrandMark(size: 88)),
        const SizedBox(height: 18),
        Center(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              children: const [
                TextSpan(
                  text: 'DEEP ',
                  style: TextStyle(color: AppColors.black),
                ),
                TextSpan(
                  text: 'FITNESS',
                  style: TextStyle(color: AppColors.goldBright),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Stronger Every Day',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
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
            hintText: 'email@domain.com or +91 phone',
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
        color: Colors.red.shade700,
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
  return authState.error.toString().replaceFirst('Bad state: ', '');
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

  await ref.read(authControllerProvider.notifier).resetPassword(email);
  if (context.mounted) {
    _showSnack(context, 'Password reset email requested.');
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
