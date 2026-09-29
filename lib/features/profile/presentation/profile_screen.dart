import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/images/dog_image.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/discover_profile.dart';
import '../../dogs/presentation/health/dog_health_tab.dart';
import '../../dogs/presentation/onboarding/dog_onboarding_screen.dart';
import '../domain/user_profile.dart';
import 'edit_owner_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';
import 'settings_screen.dart';
import 'sign_out_action.dart';

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
                const SizedBox(height: 20),
                Text(
                  ProfileStrings.myDogs,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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
                    onEdit: () => _openDogEditor(context, profile.dog.id),
                    onOpenPhoto: (index) =>
                        _openGallery(context, profile.dog.photoUrls, index),
                  ),
                  const SizedBox(height: 12),
                  DogHealthTab(
                    dogId: profile.dog.id,
                    dogName: profile.dog.name,
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DogOnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text(ProfileStrings.addDog),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final saved = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const EditOwnerProfileScreen(),
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
                if (ref.watch(isAdminProvider)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                      child: const Text(ProfileStrings.adminPanel),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => confirmAndSignOut(context, ref),
                    child: const Text(ProfileStrings.signOut),
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
      MaterialPageRoute<bool>(
        builder: (_) => EditProfileScreen(dogId: dogId),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ProfileStrings.saved)),
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
  });

  final DiscoverProfile dog;
  final String location;
  final VoidCallback onEdit;
  final ValueChanged<int> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final photo = dog.photoUrls.isEmpty ? '' : dog.photoUrls.first;
    final traits = [
      for (final tag in dog.traits) DiscoverProfile.localizeTrait(tag),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: photo.isEmpty
                        ? buildDogImage(null, seed: dog.id)
                        : buildDogImage(photo, seed: dog.id),
                  ),
                  FallbackIllustrationCaption(url: photo.isEmpty ? null : photo),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(dog.name, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${dog.breed} · ${ProfileStrings.ageLabel(dog.ageYears, dog.ageMonths)}',
            ),
            Text(
              '${ProfileStrings.genderValue(dog.gender)} · ${ProfileStrings.sizeBadge(dog.size)}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (dog.chipped)
                  const Chip(label: Text(ProfileStrings.badgeChipped)),
                if (dog.vaccinated)
                  const Chip(label: Text(ProfileStrings.badgeVaccinated)),
                if (dog.sterilized)
                  const Chip(label: Text(ProfileStrings.badgeSterilized)),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(location),
            ],
            if (dog.weightKg > 0) ...[
              const SizedBox(height: 4),
              Text(ProfileStrings.kg(dog.weightKg)),
            ],
            if (dog.bio.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                ProfileStrings.bio,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(dog.bio),
            ],
            if (traits.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => onOpenPhoto(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onEdit,
                child: const Text(ProfileStrings.editDog),
              ),
            ),
          ],
        ),
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
                title: const Text(ProfileStrings.ownerPhotoCamera),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text(ProfileStrings.cancel),
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
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ImageUploadService.upload(bytes);
      if (!url.startsWith('https://') && !url.startsWith('http://')) {
        throw StateError(ProfileStrings.ownerPhotoUploadFailed);
      }
      await ref.read(profileControllerProvider.notifier).saveOwnerCustomPhoto(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ProfileStrings.ownerPhotoUploadFailed)),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _openPhotoActions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _OwnerAvatar(
                      url: avatarUrl,
                      uploading: _uploading,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDeep,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            (avatarUrl.startsWith('http://') ||
                                    avatarUrl.startsWith('https://'))
                                ? Icons.photo_camera
                                : Icons.add_a_photo,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  if (profile.ownerLocation.isNotEmpty)
                    Text(profile.ownerLocation),
                  if (profile.ownerBio.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(profile.ownerBio),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({
    required this.url,
    required this.uploading,
  });

  final String url;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primarySoft,
      child: ClipOval(
        child: SizedBox(
          width: 56,
          height: 56,
          child: uploading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : _photoOrIcon(),
        ),
      ),
    );
  }

  Widget _photoOrIcon() {
    final usable = url.startsWith('http://') || url.startsWith('https://');
    if (!usable) {
      return const Icon(Icons.person, color: AppColors.primaryDeep, size: 28);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: 56,
      height: 56,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.person, color: AppColors.primaryDeep, size: 28);
      },
    );
  }
}
