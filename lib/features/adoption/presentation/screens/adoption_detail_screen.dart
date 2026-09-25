import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/chat_inbox.dart';
import '../../../chat/presentation/chat_screen.dart';
import '../../../../core/images/dog_image.dart';
import '../../../discover/domain/discover_profile.dart';
import '../../domain/adoption_dog.dart';
import '../adoption_strings.dart';
import '../phone_launcher.dart';

class AdoptionDetailScreen extends ConsumerWidget {
  const AdoptionDetailScreen({super.key, required this.dog});

  final AdoptionDog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(dog.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                SizedBox(
                  height: 280,
                  child: dog.imageUrls.isEmpty
                      ? buildDogImage(null)
                      : PageView.builder(
                          itemCount: dog.imageUrls.length,
                          itemBuilder: (context, index) {
                            return buildDogImage(dog.imageUrls[index]);
                          },
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
                      const SizedBox(height: 12),
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
                          _InfoChip(
                            label: AdoptionStrings.location,
                            value: dog.location,
                          ),
                          if (dog.isVaccinated)
                            const _InfoChip(
                              label: AdoptionStrings.vaccinated,
                              value: AdoptionStrings.yes,
                            ),
                          if (dog.isSterilized)
                            const _InfoChip(
                              label: AdoptionStrings.sterilized,
                              value: AdoptionStrings.yes,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: const Text(
                            AdoptionStrings.owner,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () => _openChat(context, ref),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text(AdoptionStrings.sendMessage),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: dog.contactPhone.trim().isEmpty
                            ? null
                            : () => _call(context, ref),
                        icon: const Icon(Icons.phone),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(AdoptionStrings.callLabel(dog.contactPhone)),
                        ),
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
        const SnackBar(content: Text(AdoptionStrings.callUnavailable)),
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
