import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/images/dog_image.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/theme/app_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../services/storage_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/discover_profile.dart';
import '../../dogs/presentation/health/dog_health_tab.dart';
import '../../dogs/presentation/onboarding/dog_onboarding_screen.dart';
import '../../moments/presentation/moments_controller.dart';
import '../../moments/presentation/widgets/story_widgets.dart';
import '../domain/user_profile.dart';
import 'edit_owner_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';
import 'widgets/profile_ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final hasDogs = profile.dogs.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OwnerHeader(profile: profile),
                SizedBox(height: 20),
                Text(
                  ProfileStrings.myDogs,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                if (!hasDogs)
                  Text(
                    ProfileStrings.addDogHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
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
                  const SizedBox(height: 12),
                  _DogCard(
                    dog: profile.dog,
                    location: profile.ownerLocation.isNotEmpty
                        ? profile.ownerLocation
                        : SerbiaLocations.displayPlace(profile.dog.location),
                    canDelete: profile.dogs.length > 1,
                    onEdit: () => _openDogEditor(context, profile.dog.id),
                    onDelete: () => _confirmDeleteDog(
                      context,
                      ref,
                      profile.dog.id,
                      profile.dog.name,
                    ),
                    onOpenPhoto: (index) =>
                        _openGallery(context, profile.dog.photoUrls, index),
                  ),
                  const SizedBox(height: 16),
                  StoryHighlightsRow(dogId: profile.dog.id, editable: true),
                  const SizedBox(height: 12),
                  DogHealthTab(
                    dogId: profile.dog.id,
                    dogName: profile.dog.name,
                    dogs: [
                      for (final dog in profile.dogs)
                        (id: dog.id, name: dog.name),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DogOnboardingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(ProfileStrings.addDog),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : Colors.grey.shade100,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final saved = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const EditOwnerProfileScreen(),
                          ),
                        );
                        if (saved == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ProfileStrings.saved)),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(ProfileStrings.editProfile),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDogEditor(BuildContext context, String dogId) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EditProfileScreen(dogId: dogId)),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ProfileStrings.saved)));
    }
  }

  Future<void> _confirmDeleteDog(
    BuildContext context,
    WidgetRef ref,
    String dogId,
    String dogName,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ProfileStrings.deleteDogTitle),
          content: Text('${ProfileStrings.deleteDogBody}\n\n$dogName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(ProfileStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(ProfileStrings.deleteDog),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(profileControllerProvider.notifier).deleteDog(dogId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfileStrings.dogDeleted)),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfileStrings.deleteDogFailed)),
      );
    }
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
              title: Text(ProfileStrings.photos),
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
                    child: buildDogImage(
                      urls[page],
                      seed: urls[page],
                      fit: BoxFit.contain,
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

class _DogCard extends StatelessWidget {
  const _DogCard({
    required this.dog,
    required this.location,
    required this.onEdit,
    required this.onOpenPhoto,
    this.canDelete = false,
    this.onDelete,
  });

  final DiscoverProfile dog;
  final String location;
  final VoidCallback onEdit;
  final ValueChanged<int> onOpenPhoto;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final photo = dog.photoUrls.isEmpty ? '' : dog.photoUrls.first;
    final traits = [
      for (final tag in dog.traits) DiscoverProfile.localizeTrait(tag),
    ];
    return AppCard(
      margin: EdgeInsets.zero,
      padding: AppCardTokens.innerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ProfileAvatar(
              url: photo,
              seed: dog.id,
              size: 100,
              fallbackIcon: Icons.pets,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              dog.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 4),
          Center(
            child: Text(
              '${dog.breed} · ${ProfileStrings.ageLabel(dog.ageYears, dog.ageMonths)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              MetricStatChip(
                value: ProfileStrings.ageLabel(dog.ageYears, dog.ageMonths),
                label: ProfileStrings.metricAge,
              ),
              SizedBox(width: 8),
              MetricStatChip(
                value: ProfileStrings.sizeBadge(dog.size),
                label: ProfileStrings.sizeLabel,
              ),
              SizedBox(width: 8),
              MetricStatChip(
                value: ProfileStrings.genderValue(dog.gender),
                label: ProfileStrings.gender,
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DetailPillChip(label: dog.breed),
              DetailPillChip(label: ProfileStrings.genderValue(dog.gender)),
              if (dog.chipped)
                DetailPillChip(label: ProfileStrings.badgeChipped),
              if (dog.vaccinated)
                DetailPillChip(label: ProfileStrings.badgeVaccinated),
              if (dog.sterilized)
                DetailPillChip(label: ProfileStrings.badgeSterilized),
            ],
          ),
          if (location.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              location,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          if (dog.weightKg > 0) ...[
            SizedBox(height: 4),
            Text(ProfileStrings.kg(dog.weightKg)),
          ],
          if (dog.bio.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              ProfileStrings.bio,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              dog.bio,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
          if (traits.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              ProfileStrings.personality,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in traits) PersonalityBadge(label: tag),
              ],
            ),
          ],
          if (dog.photoUrls.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dog.photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => onOpenPhoto(index),
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: buildDogImage(
                          dog.photoUrls[index],
                          seed: dog.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (canDelete && onDelete != null)
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                  ),
                  child: Text(ProfileStrings.deleteDog),
                ),
              Spacer(),
              TextButton(
                onPressed: onEdit,
                child: Text(ProfileStrings.editDog),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerHeader extends ConsumerStatefulWidget {
  const _OwnerHeader({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_OwnerHeader> createState() => _OwnerHeaderState();
}

class _OwnerHeaderState extends ConsumerState<_OwnerHeader> {
  var _uploading = false;

  bool get _hasOwnerPhoto {
    final url = ref.read(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Future<void> _openPhotoActions() async {
    if (_uploading) {
      return;
    }
    final hasPhoto = _hasOwnerPhoto;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  hasPhoto
                      ? ProfileStrings.changeOwnerPhoto
                      : ProfileStrings.setOwnerPhoto,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(ProfileStrings.ownerPhotoCamera),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(ProfileStrings.cancel),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_uploading) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final storage = StorageService();
      final previous =
          ref.read(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
      final url = source == ImageSource.camera
          ? await storage.uploadImageFromCamera(folderName: 'users')
          : await storage.uploadImageFromGallery(folderName: 'users');
      if (url == null) {
        return;
      }
      if (!url.startsWith('https://') && !url.startsWith('http://')) {
        throw StateError(ProfileStrings.ownerPhotoUploadFailed);
      }
      await ref
          .read(profileControllerProvider.notifier)
          .saveOwnerCustomPhoto(url);
      await storage.tryDeleteImageByUrl(previous);
    } catch (error) {
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: ProfileStrings.ownerPhotoUploadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final avatarUrl =
        ref.watch(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
    final dogCount = profile.dogs.length;
    final moments =
        ref.watch(momentsControllerProvider).asData?.value ?? const [];
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final momentCount = [
      for (final moment in moments)
        if (uid.isNotEmpty && moment.authorUserId == uid) moment,
    ].length;
    final breedLabel = profile.dogs.isEmpty
        ? '—'
        : (profile.dog.breed.trim().isEmpty ? '—' : profile.dog.breed);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: AppCardTokens.innerPadding,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _uploading ? null : _openPhotoActions,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    url: avatarUrl,
                    size: 96,
                    uploading: _uploading,
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDeep,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          (avatarUrl.startsWith('http://') ||
                                  avatarUrl.startsWith('https://'))
                              ? Icons.photo_camera
                              : Icons.add_a_photo,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.ownerName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (profile.ownerLocation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.ownerLocation,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          if (profile.ownerBio.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.ownerBio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          SizedBox(height: 14),
          Row(
            children: [
              MetricStatChip(
                value: '$dogCount',
                label: ProfileStrings.metricDogs,
              ),
              SizedBox(width: 8),
              MetricStatChip(
                value: '$momentCount',
                label: ProfileStrings.metricMoments,
              ),
              SizedBox(width: 8),
              MetricStatChip(value: breedLabel, label: ProfileStrings.breed),
            ],
          ),
        ],
      ),
    );
  }
}
