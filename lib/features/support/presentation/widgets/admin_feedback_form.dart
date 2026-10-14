import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_failure.dart';
import '../../domain/admin_feedback.dart';
import '../support_controller.dart';
import '../support_strings.dart';
import 'official_contact_links.dart';

class AdminFeedbackForm extends ConsumerStatefulWidget {
  const AdminFeedbackForm({super.key});

  @override
  ConsumerState<AdminFeedbackForm> createState() => _AdminFeedbackFormState();
}

class _AdminFeedbackFormState extends ConsumerState<AdminFeedbackForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = AdminFeedback.categories.first;
  var _sending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 54),
        children: [
          OfficialContactLinks(),
          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 16),
          Text(
            SupportStrings.contactIntro,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: SupportStrings.category,
            ),
            items: [
              for (final category in AdminFeedback.categories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: _sending
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _subject,
            enabled: !_sending,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: SupportStrings.subject,
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? SupportStrings.subjectRequired
                : null,
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: _message,
            enabled: !_sending,
            minLines: 5,
            maxLines: 10,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: SupportStrings.message,
              alignLabelWithHint: true,
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) {
                return SupportStrings.messageRequired;
              }
              if (text.length < 10) {
                return SupportStrings.messageTooShort;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(SupportStrings.send),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(supportControllerProvider).sendFeedback(
            category: _category,
            subject: _subject.text,
            message: _message.text,
          );
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: SupportStrings.sendError,
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    _subject.clear();
    _message.clear();
    setState(() => _sending = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(SupportStrings.sentTitle),
        content: Text(SupportStrings.sentBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(SupportStrings.ok),
          ),
        ],
      ),
    );
  }
}
