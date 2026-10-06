import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'widgets/auth_text_field.dart';

/// Opens the forgot-password dialog. Prefills [initialEmail] when present.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  String initialEmail = '',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  var _isLoading = false;

  static final _emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  String _normalizeEmail(String raw) => raw.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: _normalizeEmail(widget.initialEmail),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = _normalizeEmail(value ?? '');
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint('ForgotPassword: validacija nije prošla.');
      return;
    }

    final email = _normalizeEmail(_emailController.text);
    if (_emailController.text != email) {
      _emailController.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
    }

    setState(() => _isLoading = true);
    debugPrint('Šaljem reset e-mail na: $email');

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      debugPrint('E-mail uspešno poslat!');

      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(AppStrings.resetPasswordSentTitle)),
            ],
          ),
          content: Text(
            '${AppStrings.resetPasswordSentBodyPrefix}\n$email\n\n'
            '${AppStrings.resetPasswordSentBodySuffix}',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text(AppStrings.ok),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'ForgotPassword FirebaseAuthException code=${e.code} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      final errorMessage = switch (e.code) {
        'user-not-found' => AppStrings.resetPasswordUserNotFound,
        'invalid-email' => AppStrings.authInvalidEmail,
        'too-many-requests' => AppStrings.resetPasswordTooManyRequests,
        'network-request-failed' => AppStrings.authNetwork,
        _ => AppStrings.resetPasswordFailed,
      };

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text(AppStrings.errorTitle)),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('ForgotPassword unexpected error: $e');
      debugPrint('$stack');
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(AppStrings.errorTitle),
          content: Text('${AppStrings.resetPasswordFailedDetail}$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(AppStrings.forgotPasswordTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.forgotPasswordBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: AppStrings.emailLabel,
              hint: AppStrings.emailHint,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: _isLoading ? null : (_) => _submit(),
              validator: _validateEmail,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.sendResetLink),
        ),
      ],
    );
  }
}
