import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../../../chat/presentation/chat_inbox.dart';
import '../../../chat/presentation/chat_screen.dart';
import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_cards.dart';
import '../../../discover/domain/discover_profile.dart';
import '../../domain/adoption_dog.dart';
import '../adoption_controller.dart';
import '../adoption_strings.dart';
import '../phone_launcher.dart';

class AdoptionDetailScreen extends ConsumerWidget {
  const AdoptionDetailScreen({super.key, required this.dog});

  final AdoptionDog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final isOwner = uid.isNotEmpty && uid == dog.uploaderUserId;
    return Scaffold(
      appBar: AppBar(title: Text(dog.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                ClipRRect(
                  borderRadius: AppCardTokens.heroBottomRadius,
                  child: dog.imageUrls.isEmpty
                      ? Column(
                          children: [
                            SizedBox(
                              height: 280,
                              width: double.infinity,
                              child: buildDogImage(null, seed: dog.id),
                            ),
                            const FallbackIllustrationCaption(url: null),
                          ],
                        )
                      : SizedBox(
                          height: 280,
                          child: PageView.builder(
                            itemCount: dog.imageUrls.length,
                            itemBuilder: (context, index) {
                              final url = dog.imageUrls[index];
                              return Column(
                                children: [
                                  Expanded(
                                    child: buildDogImage(url, seed: dog.id),
                                  ),
                                  FallbackIllustrationCaption(url: url),
                                ],
                              );
                            },
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dog.name} · ${dog.age}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      CardLocationRow(label: dog.location),
                      SizedBox(height: 4),
                      CardTimeLabel(
                        label: AdoptionStrings.timeAgo(dog.createdAt),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: AdoptionStrings.breed,
                            value: dog.breed,
                          ),
                          _InfoChip(
                            label: AdoptionStrings.age,
                            value: dog.age,
                          ),
                          _InfoChip(
                            label: AdoptionStrings.size,
                            value: AdoptionStrings.sizeLabel(dog.size),
                          ),
                          if (dog.isVaccinated)
                            _InfoChip(
                              label: AdoptionStrings.vaccinated,
                              value: AdoptionStrings.yes,
                            ),
                          if (dog.isSterilized)
                            _InfoChip(
                              label: AdoptionStrings.sterilized,
                              value: AdoptionStrings.yes,
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        AdoptionStrings.story,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(dog.description),
                      const SizedBox(height: 20),
                      Card(
                        color: const Color(0xFF1E2230),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading:
                              CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            AdoptionStrings.owner,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          subtitle: Text(
                            dog.uploaderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppCardTokens.actionRadius),
                    ),
                  ),
                  onPressed: () => _markAdopted(context, ref),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(AdoptionStrings.markAdopted),
                ),
              ),
            ),
          Material(
            elevation: 8,
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DetailPrimaryButton(
                        label: AdoptionStrings.sendMessage,
                        icon: Icons.chat_bubble_outline,
                        filled: false,
                        onPressed: () => _openChat(context, ref),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DetailPrimaryButton(
                        label: AdoptionStrings.callOwner,
                        icon: Icons.phone,
                        onPressed: dog.contactPhone.trim().isEmpty
                            ? null
                            : () => _call(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAdopted(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AdoptionStrings.adoptedConfirmTitle),
          content: Text(AdoptionStrings.adoptedConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AdoptionStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AdoptionStrings.markAdopted),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      return;
    }
    await ref.read(adoptionControllerProvider.notifier).markAdopted(dog.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AdoptionStrings.adoptedDone)),
    );
    Navigator.of(context).pop();
  }

  void _openChat(BuildContext context, WidgetRef ref) {
    final profile = DiscoverProfile(
      id: dog.id,
      name: dog.name,
      ownerName: dog.uploaderName,
      ownerId: dog.uploaderUserId,
      breed: dog.breed,
      ageYears: 0,
      gender: dog.gender,
      size: dog.size,
      location: dog.location,
      bio: dog.description,
      photoUrls: dog.imageUrls,
    );
    final chatId = ref.read(chatInboxProvider.notifier).openFromMatch(profile);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: chatId),
      ),
    );
  }

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    final launched =
        await ref.read(phoneLauncherProvider).call(dog.contactPhone);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdoptionStrings.callUnavailable)),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
