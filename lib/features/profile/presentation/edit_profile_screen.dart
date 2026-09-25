import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/images/dog_image.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../discover/data/dog_profile_mapper.dart';
import '../../discover/domain/discover_profile.dart';
import '../../dogs/domain/dog_enums.dart';
import '../../dogs/presentation/onboarding/option_chips.dart';
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
  late final TextEditingController _breed;
  late final TextEditingController _ageYears;
  late final TextEditingController _ageMonths;
  late final TextEditingController _weight;
  late final TextEditingController _dogBio;
  late List<DogTemperament> _tags;
  late List<String> _photos;
  late String _gender;
  late String _size;
  late bool _vaccinated;
  late bool _chipped;
  late bool _sterilized;
  var _uploadingPhoto = false;
  var _missing = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    DiscoverProfile? dog;
    for (final item in profile.dogs) {
      if (item.id == widget.dogId) {
        dog = item;
        break;
      }
    }
    if (dog == null) {
      _missing = true;
      _dogName = TextEditingController();
      _breed = TextEditingController();
      _ageYears = TextEditingController();
      _ageMonths = TextEditingController();
      _weight = TextEditingController();
      _dogBio = TextEditingController();
      _tags = [];
      _photos = [];
      _gender = 'mužjak';
      _size = 'srednji';
      _vaccinated = false;
      _chipped = false;
      _sterilized = false;
      return;
    }
    _dogName = TextEditingController(text: dog.name);
    _breed = TextEditingController(text: dog.breed);
    _ageYears = TextEditingController(text: '${dog.ageYears}');
    _ageMonths = TextEditingController(
      text: dog.ageMonths > 0 ? '${dog.ageMonths}' : '',
    );
    _weight = TextEditingController(
      text: dog.weightKg > 0 ? dog.weightKg.toStringAsFixed(0) : '',
    );
    _dogBio = TextEditingController(text: dog.bio);
    _tags = temperamentFromStored(dog.traits);
    _photos = List<String>.from(dog.photoUrls);
    _gender = dog.gender;
    _size = dog.size;
    _vaccinated = dog.vaccinated;
    _chipped = dog.chipped;
    _sterilized = dog.sterilized;
  }

  @override
  void dispose() {
    _dogName.dispose();
    _breed.dispose();
    _ageYears.dispose();
    _ageMonths.dispose();
    _weight.dispose();
    _dogBio.dispose();
    super.dispose();
  }

  void _save() {
    final name = _dogName.text.trim();
    final breed = _breed.text.trim();
    if (name.isEmpty || breed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ProfileStrings.validation)),
      );
      return;
    }
    final invalid = ContentValidationService.validateText(name) ??
        ContentValidationService.validateText(breed) ??
        ContentValidationService.validateText(_dogBio.text, allowEmpty: true);
    if (invalid != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invalid)),
      );
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
    final weight = double.tryParse(_weight.text.trim());
    final dog = existing.copyWith(
      name: name,
      breed: breed,
      ageYears: int.tryParse(_ageYears.text.trim()) ?? existing.ageYears,
      ageMonths: int.tryParse(_ageMonths.text.trim()) ?? 0,
      gender: _gender,
      size: _size,
      weightKg: weight ?? 0,
      vaccinated: _vaccinated,
      chipped: _chipped,
      sterilized: _sterilized,
      bio: _dogBio.text.trim(),
      photoUrls: uniquePhotoUrls(_photos),
      traits: [for (final tag in _tags) tag.firestoreValue],
    );
    ref.read(profileControllerProvider.notifier).saveDog(dog);
    Navigator.of(context).pop(true);
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_uploadingPhoto) {
      return;
    }
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !mounted) {
      return;
    }
    final invalid = await ContentValidationService.validateImage(picked);
    if (invalid != null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invalid)),
      );
      return;
    }
    setState(() => _uploadingPhoto = true);
    var url = '';
    try {
      final bytes = await picked.readAsBytes();
      url = await ImageUploadService.upload(bytes);
    } catch (_) {
      url = '';
    }
    if (!mounted) {
      return;
    }
    setState(() => _uploadingPhoto = false);
    if (!(url.startsWith('https://') || url.startsWith('http://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.photoUploadFailed)),
      );
      return;
    }
    setState(() => _photos = [..._photos, url]);
  }

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: const Text(ProfileStrings.editDog)),
        body: const Center(child: Text(ProfileStrings.addDogHint)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.editDog)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dogName,
                decoration: const InputDecoration(
                  labelText: ProfileStrings.dogName,
                  hintText: ProfileStrings.dogNameHint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breed,
                decoration: const InputDecoration(
                  labelText: ProfileStrings.breed,
                  hintText: ProfileStrings.breedHint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageYears,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: ProfileStrings.ageYears,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ageMonths,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: ProfileStrings.ageMonths,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(ProfileStrings.gender),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text(ProfileStrings.genderMale),
                    selected: _gender == 'mužjak',
                    onSelected: (_) => setState(() => _gender = 'mužjak'),
                  ),
                  ChoiceChip(
                    label: const Text(ProfileStrings.genderFemale),
                    selected: _gender == 'ženka',
                    onSelected: (_) => setState(() => _gender = 'ženka'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(ProfileStrings.sizeLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text(ProfileStrings.sizeSmall),
                    selected: _size == 'mali',
                    onSelected: (_) => setState(() => _size = 'mali'),
                  ),
                  ChoiceChip(
                    label: const Text(ProfileStrings.sizeMedium),
                    selected: _size == 'srednji',
                    onSelected: (_) => setState(() => _size = 'srednji'),
                  ),
                  ChoiceChip(
                    label: const Text(ProfileStrings.sizeLarge),
                    selected: _size == 'veliki',
                    onSelected: (_) => setState(() => _size = 'veliki'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: ProfileStrings.weight,
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(ProfileStrings.vaccines),
                value: _vaccinated,
                onChanged: (value) => setState(() => _vaccinated = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(ProfileStrings.chipStatus),
                value: _chipped,
                onChanged: (value) => setState(() => _chipped = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(ProfileStrings.sterilized),
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
                            _tags =
                                _tags.where((item) => item != tag).toList();
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dogBio,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: ProfileStrings.bio,
                  hintText: ProfileStrings.bioHint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.stepPhotosTitle,
                style: Theme.of(context).textTheme.titleMedium,
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
                          : () {
                              setState(() => _photos.removeAt(i));
                            },
                    ),
                  if (_uploadingPhoto)
                    const SizedBox(
                      width: 88,
                      height: 88,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  OutlinedButton.icon(
                    onPressed: _uploadingPhoto
                        ? null
                        : () => _addPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(AppStrings.addFromGallery),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploadingPhoto
                        ? null
                        : () => _addPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text(AppStrings.addFromCamera),
                  ),
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
            child: const Text(ProfileStrings.saveChanges),
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
                : buildDogImage(url, width: 88, height: 88),
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
