import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The six digit code from the SMS.
///
/// On success nothing is navigated from here: the auth state change moves
/// the router, to onboarding or home depending on whether a profile exists.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key, required this.pending});

  final PendingVerification pending;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _codeController = TextEditingController();

  late PendingVerification _pending = widget.pending;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .confirmPhoneCode(
            verificationId: _pending.verificationId,
            smsCode: _codeController.text,
          );
    } on RepositoryFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    await ref
        .read(authServiceProvider)
        .startPhoneSignIn(
          phoneNumber: _pending.phoneNumber,
          resendToken: _pending.resendToken,
          onCodeSent: (pending) {
            if (!mounted) return;
            setState(() {
              _pending = pending;
              _busy = false;
            });
          },
          onFailed: (failure) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _error = failure.message;
            });
          },
          onAutoVerified: (_) {
            if (mounted) setState(() => _busy = false);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the code',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sent to ${_pending.phoneNumber}',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Six digit code'),
                    onSubmitted: (_) => _confirm(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else
                    DfPrimaryButton(label: 'Verify', onPressed: _confirm),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : _resend,
                    child: const Text('Send a new code'),
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
