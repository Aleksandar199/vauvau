import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/images/dog_image.dart';
import '../../adoption/presentation/phone_launcher.dart';
import '../domain/lost_dog.dart';
import 'lost_dog_strings.dart';

Future<void> showLostDogSightingSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LostDog dog,
}) {
  final found = dog.isFoundListing;
  return showModalBottomSheet<void>(
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
              const SizedBox(height: 8),
              Text(
                found ? LostDogStrings.finderBody : LostDogStrings.sightingBody,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _callOwner(context, ref, dog.contactPhone);
                },
                child: Text(
                  found ? LostDogStrings.callFinder : LostDogStrings.callOwner,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _smsOwner(context, dog);
                },
                child: const Text(LostDogStrings.sendSms),
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
        title: const Text(LostDogStrings.emergencyTitle),
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
              const SizedBox(height: 12),
              Text(
                '${dog.dogName}, ${dog.placeLabel}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(LostDogStrings.lostOn(LostDogStrings.formatDate(dog.lostDate))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(LostDogStrings.understand),
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
            child: const Text(LostDogStrings.sighting),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _callOwner(context, ref, dog.contactPhone);
            },
            child: const Text(LostDogStrings.callOwner),
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
  return showModalBottomSheet<void>(
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
                borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 12),
              Text(
                LostDogStrings.missingHeadline(dog.dogName),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(LostDogStrings.breedLine(dog.breed)),
              Text(LostDogStrings.place(dog.city, dog.neighborhood)),
              Text(LostDogStrings.lostOn(LostDogStrings.formatDate(dog.eventDate))),
              if (dog.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(dog.description),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await showLostDogSightingSheet(
                    context: context,
                    ref: ref,
                    dog: dog,
                  );
                },
                child: const Text(LostDogStrings.sighting),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text(LostDogStrings.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _callOwner(
  BuildContext context,
  WidgetRef ref,
  String phone,
) async {
  final ok = await ref.read(phoneLauncherProvider).call(phone);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(LostDogStrings.callUnavailable)),
    );
  }
}

Future<void> _smsOwner(BuildContext context, LostDog dog) async {
  final compact = dog.contactPhone.replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(LostDogStrings.callUnavailable)),
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
        const SnackBar(content: Text(LostDogStrings.callUnavailable)),
      );
    }
  }
}
