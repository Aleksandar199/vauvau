import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_cards.dart';
import '../../../core/widgets/comment_like_button.dart';
import '../../adoption/presentation/phone_launcher.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/lost_dog.dart';
import 'lost_dog_strings.dart';
import 'lost_dogs_controller.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

Future<void> showLostDogSightingSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LostDog dog,
}) {
  final found = dog.isFoundListing;
  return showAppBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                found
                    ? LostDogStrings.finderTitle
                    : LostDogStrings.sightingTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                found ? LostDogStrings.finderBody : LostDogStrings.sightingBody,
              ),
              SizedBox(height: 16),
              DetailPrimaryButton(
                label: found
                    ? LostDogStrings.callFinder
                    : LostDogStrings.callOwner,
                icon: Icons.phone,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _callOwner(context, ref, dog.contactPhone);
                },
              ),
              SizedBox(height: 8),
              DetailPrimaryButton(
                label: LostDogStrings.sendSms,
                icon: Icons.chat_bubble_outline,
                filled: false,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _smsOwner(context, dog);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showLostDogEmergencyDialog({
  required BuildContext context,
  required WidgetRef ref,
  required LostDog dog,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(LostDogStrings.emergencyTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: buildDogImage(dog.imageUrl, seed: dog.id),
                    ),
                    FallbackIllustrationCaption(url: dog.imageUrl),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                '${dog.dogName}, ${dog.placeLabel}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 6),
              Text(LostDogStrings.lostOn(LostDogStrings.formatDate(dog.lostDate))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(LostDogStrings.understand),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await showLostDogSightingSheet(
                context: context,
                ref: ref,
                dog: dog,
              );
            },
            child: Text(LostDogStrings.sighting),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _callOwner(context, ref, dog.contactPhone);
            },
            child: Text(LostDogStrings.callOwner),
          ),
        ],
      );
    },
  );
}

Future<void> showLostDogProfileSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LostDog dog,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: AppCardTokens.heroBottomRadius,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: buildDogImage(dog.imageUrl, seed: dog.id),
                    ),
                    FallbackIllustrationCaption(url: dog.imageUrl),
                  ],
                ),
              ),
              SizedBox(height: 12),
              CardTitleText(
                text: LostDogStrings.missingHeadline(dog.dogName),
              ),
              SizedBox(height: 6),
              Text(LostDogStrings.breedLine(dog.breed)),
              SizedBox(height: 4),
              CardLocationRow(
                label: LostDogStrings.place(dog.city, dog.neighborhood),
              ),
              SizedBox(height: 4),
              CardTimeLabel(
                label: LostDogStrings.lostOn(
                  LostDogStrings.formatDate(dog.eventDate),
                ),
              ),
              if (dog.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(dog.description),
              ],
              SizedBox(height: 16),
              DetailPrimaryButton(
                label: LostDogStrings.sighting,
                icon: Icons.visibility,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await showLostDogSightingSheet(
                    context: context,
                    ref: ref,
                    dog: dog,
                  );
                },
              ),
              SizedBox(height: 8),
              DetailPrimaryButton(
                label: LostDogStrings.leaveComment,
                icon: Icons.chat_bubble_outline,
                filled: false,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await showLostDogCommentsSheet(
                    context: context,
                    ref: ref,
                    dog: dog,
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(LostDogStrings.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showLostDogCommentsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LostDog dog,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _LostDogCommentsSheet(dog: dog),
      );
    },
  );
}

class _LostDogCommentsSheet extends ConsumerStatefulWidget {
  const _LostDogCommentsSheet({required this.dog});

  final LostDog dog;

  @override
  ConsumerState<_LostDogCommentsSheet> createState() =>
      _LostDogCommentsSheetState();
}

class _LostDogCommentsSheetState extends ConsumerState<_LostDogCommentsSheet> {
  final _input = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments =
        ref.watch(lostDogCommentsProvider(widget.dog.id)).value ?? const [];
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    return SafeArea(
      child: SizedBox(
        height: 440,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  LostDogStrings.commentsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: comments.isEmpty
                  ? Center(child: Text(LostDogStrings.commentEmpty))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.authorName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(comment.text),
                                    const SizedBox(height: 4),
                                    Text(
                                      LostDogStrings.timeAgo(comment.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              CommentLikeButton(
                                liked: comment.isLikedBy(uid),
                                count: comment.likeCount,
                                tooltip: LostDogStrings.likeComment,
                                onPressed: () => _toggleLike(comment.id),
                              ),
                            ],
                          ),
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
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: LostDogStrings.commentHint,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(String commentId) async {
    try {
      await ref
          .read(lostDogsControllerProvider.notifier)
          .toggleCommentLike(widget.dog.id, commentId);
    } catch (error) {
      debugPrint('Lost dog comment like UI error: $error');
      if (!mounted) {
        return;
      }
      final details = error.toString();
      final message = details.contains('permission-denied')
          ? LostDogStrings.commentPermissionDenied
          : LostDogStrings.likeFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(lostDogsControllerProvider.notifier)
          .addComment(widget.dog.id, text);
      if (!mounted) {
        return;
      }
      _input.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LostDogStrings.commentSent)),
      );
    } catch (error) {
      debugPrint('Lost dog comment UI error: $error');
      if (mounted) {
        final details = error.toString();
        final message = details.contains('permission-denied')
            ? LostDogStrings.commentPermissionDenied
            : LostDogStrings.commentFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

Future<void> _callOwner(
  BuildContext context,
  WidgetRef ref,
  String phone,
) async {
  final ok = await ref.read(phoneLauncherProvider).call(phone);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LostDogStrings.callUnavailable)),
    );
  }
}

Future<void> _smsOwner(BuildContext context, LostDog dog) async {
  final compact = dog.contactPhone.replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LostDogStrings.callUnavailable)),
      );
    }
    return;
  }
  final uri = Uri(
    scheme: 'sms',
    path: compact,
    queryParameters: {
      'body': dog.isFoundListing
          ? LostDogStrings.finderSmsBody()
          : LostDogStrings.smsBody(dog.dogName),
    },
  );
  if (!await canLaunchUrl(uri) || !await launchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LostDogStrings.callUnavailable)),
      );
    }
  }
}
