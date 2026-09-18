import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../discover/presentation/discover_image.dart';
import '../domain/user_profile.dart';
import 'edit_profile_screen.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final dog = profile.dog;
    final photo = dog.photoUrls.isEmpty ? '' : dog.photoUrls.first;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _OwnerHeader(profile: profile),
              const SizedBox(height: 16),
              Text(
                ProfileStrings.myDogs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in profile.dogs)
                    ChoiceChip(
                      label: Text(item.name),
                      selected: item.id == profile.selectedDogId,
                      onSelected: (_) => ref
                          .read(profileControllerProvider.notifier)
                          .selectDog(item.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(ProfileStrings.sizeBadge(dog.size))),
                  if (dog.chipped)
                    const Chip(label: Text(ProfileStrings.badgeChipped)),
                  if (dog.vaccinated)
                    const Chip(label: Text(ProfileStrings.badgeVaccinated)),
                  if (dog.sterilized)
                    const Chip(label: Text(ProfileStrings.badgeSterilized)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo.isEmpty
                          ? const ColoredBox(
                              color: AppColors.lightOutline,
                              child: Center(child: Icon(Icons.pets, size: 72)),
                            )
                          : Image(
                              image: discoverImageOf(context, photo),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const ColoredBox(
                                  color: AppColors.lightOutline,
                                  child: Center(
                                    child: Icon(Icons.pets, size: 72),
                                  ),
                                );
                              },
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xCC0F172A)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dog.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text(
                              '${dog.breed} • ${ProfileStrings.ageLabel(dog.ageYears, dog.ageMonths)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(dog.location),
              const SizedBox(height: 8),
              DistancePill(label: dog.distanceLabel),
              const SizedBox(height: 16),
              Text(
                ProfileStrings.bio,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(dog.bio),
              const SizedBox(height: 16),
              Text(
                ProfileStrings.personality,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in dog.traits) PersonalityBadge(label: tag),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                ProfileStrings.photos,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dog.photoUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final url = dog.photoUrls[index];
                  return InkWell(
                    onTap: () => _openGallery(context, dog.photoUrls, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: discoverImageOf(context, url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: AppColors.lightOutline,
                            child: Icon(Icons.pets),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final saved = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      if (saved == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(ProfileStrings.saved)),
                        );
                      }
                    },
                    child: const Text(ProfileStrings.editProfile),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const Text(ProfileStrings.settings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openGallery(
    BuildContext context,
    List<String> urls,
    int index,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text(ProfileStrings.photos),
              leading: IconButton(
                tooltip: ProfileStrings.closePhoto,
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            body: PageView.builder(
              controller: PageController(initialPage: index),
              itemCount: urls.length,
              itemBuilder: (context, page) {
                return InteractiveViewer(
                  child: Center(
                    child: Image(
                      image: discoverImageOf(context, urls[page]),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.pets, size: 72);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                profile.ownerName.substring(0, 1),
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.ownerName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(profile.ownerLocation),
                  Text(profile.phone),
                  Text(profile.ownerBio),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
