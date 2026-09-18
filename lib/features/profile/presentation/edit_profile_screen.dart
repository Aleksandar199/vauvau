import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../discover/presentation/discover_image.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

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
  late final TextEditingController _ownerName;
  late final TextEditingController _ownerBio;
  late final TextEditingController _ownerLocation;
  late final TextEditingController _phone;
  late List<String> _tags;
  late List<String> _photos;
  late String _cityId;
  late String _neighborhoodId;
  late String _gender;
  late String _size;
  late bool _vaccinated;
  late bool _chipped;
  late bool _sterilized;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final dog = profile.dog;
    _dogName = TextEditingController(text: dog.name);
    _breed = TextEditingController(text: dog.breed);
    _ageYears = TextEditingController(text: '${dog.ageYears}');
    _ageMonths = TextEditingController(text: '${dog.ageMonths}');
    _weight = TextEditingController(text: dog.weightKg.toStringAsFixed(0));
    _dogBio = TextEditingController(text: dog.bio);
    _ownerName = TextEditingController(text: profile.ownerName);
    _ownerBio = TextEditingController(text: profile.ownerBio);
    _ownerLocation = TextEditingController(text: profile.ownerLocation);
    _phone = TextEditingController(text: profile.phone);
    _tags = List<String>.from(dog.traits);
    _photos = List<String>.from(dog.photoUrls);
    _gender = dog.gender;
    _size = dog.size;
    _vaccinated = dog.vaccinated;
    _chipped = dog.chipped;
    _sterilized = dog.sterilized;
    final parts = dog.location.split(' - ');
    _cityId = _cityIdFromName(parts.first);
    _neighborhoodId =
        _neighborhoodIdFromName(_cityId, parts.length > 1 ? parts[1] : '');
  }

  @override
  void dispose() {
    _dogName.dispose();
    _breed.dispose();
    _ageYears.dispose();
    _ageMonths.dispose();
    _weight.dispose();
    _dogBio.dispose();
    _ownerName.dispose();
    _ownerBio.dispose();
    _ownerLocation.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _cityIdFromName(String name) {
    for (final city in SerbiaLocations.cities) {
      if (city.name == name) {
        return city.id;
      }
    }
    return SerbiaLocations.cities.first.id;
  }

  String _neighborhoodIdFromName(String cityId, String name) {
    final city = SerbiaLocations.cityById(cityId);
    if (city == null) {
      return '';
    }
    for (final hood in city.neighborhoods) {
      if (hood.name == name) {
        return hood.id;
      }
    }
    return city.neighborhoods.first.id;
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
    final city = SerbiaLocations.cityById(_cityId);
    String neighborhood = '';
    if (city != null) {
      for (final hood in city.neighborhoods) {
        if (hood.id == _neighborhoodId) {
          neighborhood = hood.name;
          break;
        }
      }
    }
    final current = ref.read(profileControllerProvider);
    final dog = current.dog.copyWith(
      name: name,
      breed: breed,
      ageYears: int.tryParse(_ageYears.text.trim()) ?? current.dog.ageYears,
      ageMonths: int.tryParse(_ageMonths.text.trim()) ?? current.dog.ageMonths,
      gender: _gender,
      size: _size,
      weightKg: double.tryParse(_weight.text.trim()) ?? current.dog.weightKg,
      vaccinated: _vaccinated,
      chipped: _chipped,
      sterilized: _sterilized,
      bio: _dogBio.text.trim(),
      ownerName: _ownerName.text.trim(),
      location: '${city?.name ?? current.dog.cityName} - $neighborhood',
      photoUrls: List<String>.from(_photos),
      traits: List<String>.from(_tags),
    );
    final dogs = [
      for (final item in current.dogs)
        if (item.id == dog.id) dog else item,
    ];
    ref.read(profileControllerProvider.notifier).save(
          current.copyWith(
            ownerName: _ownerName.text.trim().isEmpty
                ? current.ownerName
                : _ownerName.text.trim(),
            ownerBio: _ownerBio.text.trim(),
            ownerLocation: _ownerLocation.text.trim().isEmpty
                ? current.ownerLocation
                : _ownerLocation.text.trim(),
            phone: _phone.text.trim().isEmpty ? current.phone : _phone.text.trim(),
            dogs: dogs,
            selectedDogId: dog.id,
          ),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final city = SerbiaLocations.cityById(_cityId);
    final neighborhoods = city?.neighborhoods ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.editProfile)),
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breed,
              decoration: const InputDecoration(
                labelText: ProfileStrings.breed,
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
                for (final tag in ProfileStrings.personalityOptions)
                  FilterChip(
                    label: Text(tag),
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
            TextFormField(
              controller: _dogBio,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: ProfileStrings.bio,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerName,
              decoration: const InputDecoration(
                labelText: ProfileStrings.ownerName,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerLocation,
              decoration: const InputDecoration(
                labelText: ProfileStrings.ownerLocation,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: ProfileStrings.phone,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerBio,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: ProfileStrings.ownerBio,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(ProfileStrings.city),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final item in neighborhoods)
                  ChoiceChip(
                    label: Text(item.name),
                    selected: _neighborhoodId == item.id,
                    onSelected: (_) {
                      setState(() => _neighborhoodId = item.id);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              ProfileStrings.photos,
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
                    onRemove: () {
                      setState(() => _photos.removeAt(i));
                    },
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _photos = [
                        ..._photos,
                        'placeholder://${_photos.length + 1}',
                      ];
                    });
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text(ProfileStrings.addPhoto),
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
  const _PhotoTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

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
                : Image(
                    image: discoverImageOf(context, url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: AppColors.lightOutline,
                        child: Center(child: Icon(Icons.pets)),
                      );
                    },
                  ),
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
