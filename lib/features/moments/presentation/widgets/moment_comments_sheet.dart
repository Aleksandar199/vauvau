import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moments_controller.dart';
import '../moments_strings.dart';
import '../pointer_safe.dart';

Future<void> showMomentCommentsSheet(BuildContext context, String momentId) {
  return afterPointerSettles(() async {
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _CommentsSheet(momentId: momentId),
        );
      },
    );
  });
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.momentId});

  final String momentId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments =
        ref.watch(momentCommentsProvider(widget.momentId)).value ?? const [];
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  MomentsStrings.commentsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(comment.authorName),
                    subtitle: Text(comment.text),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: MomentsStrings.commentHint,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) {
      return;
    }
    _input.clear();
    await ref
        .read(momentsControllerProvider.notifier)
        .addComment(widget.momentId, text);
  }
}
