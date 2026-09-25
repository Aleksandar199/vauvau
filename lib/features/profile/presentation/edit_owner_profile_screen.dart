import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/serbia_locations.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

class EditOwnerProfileScreen extends ConsumerStatefulWidget {
  const EditOwnerProfileScreen({super.key});

  @override
  ConsumerState<EditOwnerProfileScreen> createState() =>
      _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState extends ConsumerState<EditOwnerProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _cityId;
  late String _neighborhoodId;
  var _uploading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _name = TextEditingController(text: profile.ownerName);
    _bio = TextEditingController(text: profile.ownerBio);
    _cityId = profile.ownerCityId.isEmpty
        ? SerbiaLocations.cities.first.id
        : profile.ownerCityId;
    final city = SerbiaLocations.cityById(_cityId) ?? SerbiaLocations.cities.first;
    _neighborhoodId = profile.ownerNeighborhoodId.isEmpty
        ? city.neighborhoods.first.id
        : profile.ownerNeighborhoodId;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_uploading) {
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ImageUploadService.upload(bytes);
      if (!url.startsWith('http')) {
        throw StateError(AppStrings.photoUploadFailed);
      }
      await ref.read(profileControllerProvider.notifier).saveOwnerCustomPhoto(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.photoUploadFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _save() {
    final invalid = ContentValidationService.validateText(
          _name.text,
        ) ??
        ContentValidationService.validateText(_bio.text, allowEmpty: true);
    if (invalid != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(invalid)));
      return;
    }
    final city = SerbiaLocations.cityById(_cityId);
    var neighborhood = '';
    if (city != null) {
      for (final hood in city.neighborhoods) {
        if (hood.id == _neighborhoodId) {
          neighborhood = hood.name;
          break;
        }
      }
    }
    final current = ref.read(profileControllerProvider);
    ref.read(profileControllerProvider.notifier).save(
          current.copyWith(
            ownerName: _name.text.trim(),
            ownerBio: _bio.text.trim(),
            ownerLocation: SerbiaLocations.formatPlace(
              city?.name ?? '',
              neighborhood,
            ),
            ownerCityId: _cityId,
            ownerNeighborhoodId: _neighborhoodId,
            dogs: [
              for (final dog in current.dogs)
                dog.copyWith(
                  location: SerbiaLocations.formatPlace(
                    city?.name ?? '',
                    neighborhood,
                  ),
                ),
            ],
          ),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final city = SerbiaLocations.cityById(_cityId);
    final neighborhoods = city?.neighborhoods ?? [];
    final profile = ref.watch(profileControllerProvider);
    final email = profile.ownerEmail;
    final avatarUrl =
        ref.watch(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
    final hasPhoto =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.editProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: hasPhoto ? NetworkImage(avatarUrl) : null,
                      child: _uploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : (hasPhoto
                              ? null
                              : const Icon(Icons.person, size: 36)),
                    ),
                    IconButton.filledTonal(
                      onPressed: _uploading ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(AppStrings.ownerPhotoLabel),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: ProfileStrings.ownerName,
              border: OutlineInputBorder(),
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: AppStrings.emailLabel,
                border: OutlineInputBorder(),
              ),
              child: Text(email),
            ),
          ],
          const SizedBox(height: 16),
          Text(ProfileStrings.city),
          Wrap(
            spacing: 8,
            children: [
              for (final item in SerbiaLocations.cities)
                ChoiceChip(
                  label: Text(item.name),
                  selected: _cityId == item.id,
                  onSelected: (_) {
                    setState(() {
                      _cityId = item.id;
                      _neighborhoodId = item.neighborhoods.first.id;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(ProfileStrings.neighborhood),
          Wrap(
            spacing: 8,
            children: [
              for (final item in neighborhoods)
                ChoiceChip(
                  label: Text(item.name),
                  selected: _neighborhoodId == item.id,
                  onSelected: (_) =>
                      setState(() => _neighborhoodId = item.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: ProfileStrings.ownerBio,
              hintText: ProfileStrings.ownerBioHint,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            onPressed: _save,
            child: const Text(ProfileStrings.saveChanges),
          ),
        ),
      ),
    );
  }
}
