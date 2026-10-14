import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/dog_breeds.dart';
import '../../../core/images/dog_image.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../../core/widgets/breed_field.dart';
import '../../../services/storage_service.dart';
import '../../discover/data/dog_profile_mapper.dart';
import '../../discover/domain/discover_profile.dart';
import '../../dogs/domain/dog_enums.dart';
import '../../dogs/domain/dog_preference_tags.dart';
import '../../dogs/presentation/dog_providers.dart';
import '../../dogs/presentation/onboarding/option_chips.dart';
import '../../dogs/presentation/widgets/preference_chip_group.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.dogId});

  final String dogId;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dogName;
  late final TextEditingController _customBreed;
  late final TextEditingController _ageYears;
  late final TextEditingController _ageMonths;
  late final TextEditingController _weight;
  late final TextEditingController _dogBio;
  late String _breed;
  late List<DogTemperament> _tags;
  late List<String> _likes;
  late List<String> _dislikes;
  late List<String> _photos;
  late String _gender;
  late String _size;
  late bool _vaccinated;
  late bool _chipped;
  late bool _sterilized;
  var _uploadingPhoto = false;
  var _missing = false;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    final dog = _resolveDog();
    if (dog == null) {
      _missing = true;
      _dogName = TextEditingController();
      _breed = '';
      _customBreed = TextEditingController();
      _ageYears = TextEditingController();
      _ageMonths = TextEditingController();
      _weight = TextEditingController();
      _dogBio = TextEditingController();
      _tags = [];
      _likes = [];
      _dislikes = [];
      _photos = [];
      _gender = '';
      _size = 'srednji';
      _vaccinated = false;
      _chipped = false;
      _sterilized = false;
      return;
    }
    _dogName = TextEditingController(text: dog.name);
    _breed = dog.breed;
    final isCustom = DogBreeds.dropdownValue(_breed) == DogBreeds.customId;
    _customBreed = TextEditingController(text: isCustom ? _breed : '');
    _ageYears = TextEditingController(
      text: dog.ageYears > 0 ? '${dog.ageYears}' : '',
    );
    _ageMonths = TextEditingController(
      text: dog.ageMonths > 0 ? '${dog.ageMonths}' : '',
    );
    _weight = TextEditingController(
      text: dog.weightKg > 0 ? dog.weightKg.toStringAsFixed(0) : '',
    );
    _dogBio = TextEditingController(text: dog.bio);
    _tags = temperamentFromStored(dog.traits);
    _likes = List<String>.from(dog.likesTags);
    _dislikes = List<String>.from(dog.dislikesTags);
    _photos = List<String>.from(dog.photoUrls);
    // Normalize EN/SR stored values so chips match registration data.
    _gender = normalizeDogGender(dog.gender);
    _size = normalizeDogSize(dog.size);
    if (_size.isEmpty) {
      _size = 'srednji';
    }
    _vaccinated = dog.vaccinated;
    _chipped = dog.chipped;
    _sterilized = dog.sterilized;
  }

  DiscoverProfile? _resolveDog() {
    final profile = ref.read(profileControllerProvider);
    for (final item in profile.dogs) {
      if (item.id == widget.dogId) {
        return item;
      }
    }
    final ownerDogs = ref.read(ownerDogsProvider).asData?.value ?? const [];
    for (final dog in ownerDogs) {
      if (dog.id == widget.dogId) {
        final ownerName = profile.ownerName;
        return discoverProfileFromDog(dog, ownerName: ownerName);
      }
    }
    return null;
  }

  @override
  void dispose() {
    _dogName.dispose();
    _customBreed.dispose();
    _ageYears.dispose();
    _ageMonths.dispose();
    _weight.dispose();
    _dogBio.dispose();
    super.dispose();
  }

  void _save() {
    final name = _dogName.text.trim();
    final breed = _breed.trim();
    if (name.isEmpty || breed.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ProfileStrings.validation)));
      return;
    }
    final invalid =
        ContentValidationService.validateText(name) ??
        ContentValidationService.validateText(breed) ??
        ContentValidationService.validateText(_dogBio.text, allowEmpty: true);
    if (invalid != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(invalid)));
      return;
    }
    final current = ref.read(profileControllerProvider);
    DiscoverProfile? existing;
    for (final item in current.dogs) {
      if (item.id == widget.dogId) {
        existing = item;
        break;
      }
    }
    if (existing == null) {
      return;
    }
    final gender = normalizeDogGender(_gender);
    if (gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfileStrings.genderRequired)),
      );
      return;
    }
    final weight = double.tryParse(_weight.text.trim());
    final dog = existing.copyWith(
      name: name,
      breed: breed,
      ageYears: int.tryParse(_ageYears.text.trim()) ?? existing.ageYears,
      ageMonths: int.tryParse(_ageMonths.text.trim()) ?? 0,
      gender: gender,
      size: normalizeDogSize(_size),
      weightKg: weight ?? 0,
      vaccinated: _vaccinated,
      chipped: _chipped,
      sterilized: _sterilized,
      bio: _dogBio.text.trim(),
      photoUrls: uniquePhotoUrls(_photos),
      traits: [for (final tag in _tags) tag.firestoreValue],
      likesTags: List<String>.from(_likes),
      dislikesTags: List<String>.from(_dislikes),
    );
    ref.read(profileControllerProvider.notifier).saveDog(dog);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_uploadingPhoto) {
      return;
    }
    final remaining = AppStrings.maxDogPhotos - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.photoLimitReached)),
      );
      return;
    }
    setState(() => _uploadingPhoto = true);
    try {
      if (source == ImageSource.camera) {
        final url = await _storage.uploadImageFromCamera(folderName: 'pets');
        if (!mounted) {
          return;
        }
        if (url == null) {
          return;
        }
        if (!(url.startsWith('https://') || url.startsWith('http://'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.photoUploadFailed)),
          );
          return;
        }
        final next = [..._photos, url];
        setState(() => _photos = next);
        await _persistPhotos(next);
        return;
      }

      final urls = await _storage.uploadImagesFromGallery(
        folderName: 'pets',
        limit: remaining,
      );
      if (!mounted) {
        return;
      }
      if (urls.isEmpty) {
        return;
      }
      final next = uniquePhotoUrls([..._photos, ...urls])
          .take(AppStrings.maxDogPhotos)
          .toList();
      setState(() => _photos = next);
      // Persist downloadUrl to Firestore immediately (not only on Save).
      await _persistPhotos(next);
    } catch (error) {
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: AppStrings.photoUploadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _removePhotoAt(int index) async {
    if (index < 0 || index >= _photos.length || _uploadingPhoto) {
      return;
    }
    final removed = _photos[index];
    final next = [..._photos]..removeAt(index);
    setState(() => _photos = next);
    await _persistPhotos(next);
    await _storage.tryDeleteImageByUrl(removed);
  }

  Future<void> _persistPhotos(List<String> photos) async {
    final current = ref.read(profileControllerProvider);
    DiscoverProfile? existing;
    for (final item in current.dogs) {
      if (item.id == widget.dogId) {
        existing = item;
        break;
      }
    }
    if (existing == null) {
      return;
    }
    final updated = existing.copyWith(photoUrls: uniquePhotoUrls(photos));
    ref.read(profileControllerProvider.notifier).saveDog(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: Text(ProfileStrings.editDog)),
        body: Center(child: Text(ProfileStrings.addDogHint)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(ProfileStrings.editDog)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dogName,
                decoration: InputDecoration(
                  labelText: ProfileStrings.dogName,
                  hintText: ProfileStrings.dogNameHint,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              BreedField(
                breed: _breed,
                customBreedController: _customBreed,
                onBreedChanged: (value) => setState(() => _breed = value),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _dogBio,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: ProfileStrings.bio,
                  hintText: ProfileStrings.bioHint,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageYears,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: ProfileStrings.ageYears,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ageMonths,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: ProfileStrings.ageMonths,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(ProfileStrings.gender),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(ProfileStrings.genderMale),
                    selected: _gender == 'mužjak',
                    onSelected: (_) => setState(() => _gender = 'mužjak'),
                  ),
                  ChoiceChip(
                    label: Text(ProfileStrings.genderFemale),
                    selected: _gender == 'ženka',
                    onSelected: (_) => setState(() => _gender = 'ženka'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(ProfileStrings.sizeLabel),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(ProfileStrings.sizeSmall),
                    selected: _size == 'mali',
                    onSelected: (_) => setState(() => _size = 'mali'),
                  ),
                  ChoiceChip(
                    label: Text(ProfileStrings.sizeMedium),
                    selected: _size == 'srednji',
                    onSelected: (_) => setState(() => _size = 'srednji'),
                  ),
                  ChoiceChip(
                    label: Text(ProfileStrings.sizeLarge),
                    selected: _size == 'veliki',
                    onSelected: (_) => setState(() => _size = 'veliki'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ProfileStrings.weight,
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ProfileStrings.vaccines),
                value: _vaccinated,
                onChanged: (value) => setState(() => _vaccinated = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ProfileStrings.chipStatus),
                value: _chipped,
                onChanged: (value) => setState(() => _chipped = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ProfileStrings.sterilized),
                value: _sterilized,
                onChanged: (value) => setState(() => _sterilized = value),
              ),
              Text(ProfileStrings.personality),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in DogTemperament.values)
                    FilterChip(
                      label: Text(temperamentLabel(tag)),
                      selected: _tags.contains(tag),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _tags = [..._tags, tag];
                          } else {
                            _tags = _tags.where((item) => item != tag).toList();
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PreferenceChipGroup(
                title: ProfileStrings.likesTitle,
                options: DogPreferenceTags.likes,
                selected: _likes,
                onToggle: (tag) =>
                    setState(() => _likes = togglePreference(_likes, tag)),
                selectedColor: const Color(0xFF2E7D32),
                selectedForeground: Colors.white,
              ),
              const SizedBox(height: 16),
              PreferenceChipGroup(
                title: ProfileStrings.dislikesTitle,
                options: DogPreferenceTags.dislikes,
                selected: _dislikes,
                onToggle: (tag) => setState(
                  () => _dislikes = togglePreference(_dislikes, tag),
                ),
                selectedColor: const Color(0xFFC62828),
                selectedForeground: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                AppStrings.stepPhotosTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.photoCountLabel(_photos.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    _PhotoTile(
                      url: _photos[i],
                      onRemove: _uploadingPhoto
                          ? null
                          : () => _removePhotoAt(i),
                    ),
                  if (_uploadingPhoto)
                    const SizedBox(
                      width: 88,
                      height: 88,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_photos.length < AppStrings.maxDogPhotos) ...[
                    OutlinedButton.icon(
                      onPressed: _uploadingPhoto
                          ? null
                          : () => _addPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(AppStrings.addFromGallery),
                    ),
                    OutlinedButton.icon(
                      onPressed: _uploadingPhoto
                          ? null
                          : () => _addPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(AppStrings.addFromCamera),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            onPressed: _save,
            child: Text(ProfileStrings.saveChanges),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final placeholder = url.startsWith('placeholder:');
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 88,
            height: 88,
            child: placeholder
                ? const ColoredBox(
                    color: AppColors.lightOutline,
                    child: Center(child: Icon(Icons.pets)),
                  )
                : buildDogImage(url, seed: url, width: 88, height: 88),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filledTonal(
            tooltip: ProfileStrings.removePhoto,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
      ],
    );
  }
}
