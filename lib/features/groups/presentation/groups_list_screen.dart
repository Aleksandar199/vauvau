import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/content_validation_service.dart';
import '../domain/groups_models.dart';
import 'group_chat_screen.dart';
import 'groups_controller.dart';
import 'groups_strings.dart';
import 'widgets/group_card.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider);
    final memberId = ref.watch(groupsMemberIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(GroupsStrings.title),
        actions: [
          IconButton(
            tooltip: GroupsStrings.createGroup,
            onPressed: () => _showCreateGroupSheet(context),
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Text(
            GroupsStrings.subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final group in groups) ...[
            GroupCard(
              group: group,
              isMember: group.isMember(memberId),
              onJoin: () => _join(context, ref, group),
              onOpenChat: () => _openChat(context, group),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _join(
    BuildContext context,
    WidgetRef ref,
    BreedGroup group,
  ) async {
    await ref.read(groupsControllerProvider.notifier).join(group.id);
    if (!context.mounted) {
      return;
    }
    await _openChat(context, group);
  }

  Future<void> _openChat(BuildContext context, BreedGroup group) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupChatScreen(groupId: group.id),
      ),
    );
  }

  Future<void> _showCreateGroupSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateGroupSheet(),
    );
  }
}

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              GroupsStrings.createGroupTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: GroupsStrings.groupName,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return GroupsStrings.nameRequired;
                }
                return ContentValidationService.validateTitle(value!);
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isLoading,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: GroupsStrings.groupDescription,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(GroupsStrings.submitGroup),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(groupsControllerProvider.notifier)
          .createGroup(
            title: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );

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
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(GroupsStrings.requestSentTitle)),
            ],
          ),
          content: Text(GroupsStrings.requestSentBody),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(GroupsStrings.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      final details = e.toString().replaceFirst('Exception: ', '').trim();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text(GroupsStrings.createErrorTitle)),
            ],
          ),
          content: Text(
            GroupsStrings.createErrorBody(
              details.isEmpty ? GroupsStrings.createFailed : details,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(GroupsStrings.close),
            ),
          ],
        ),
      );
    }
  }
}
