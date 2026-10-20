import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/serbia_locations.dart';
import '../../../location/presentation/home_city_provider.dart';
import '../../../../core/network/network_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/content_validation_service.dart';
import '../../../../core/widgets/breed_field.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../adoption_controller.dart';
import '../adoption_strings.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

class AddAdoptionDogScreen extends ConsumerStatefulWidget {
  const AddAdoptionDogScreen({super.key});

  @override
  ConsumerState<AddAdoptionDogScreen> createState() =>
      _AddAdoptionDogScreenState();
}

Future<bool?> showAddAdoptionDogSheet(BuildContext context) {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.92;
      return SizedBox(
        height: height,
        child: const AddAdoptionDogScreen(),
      );
    },
  );
}

class _AddAdoptionDogScreenState extends ConsumerState<AddAdoptionDogScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _customBreed;
  late final TextEditingController _age;
  late final TextEditingController _story;
  late final TextEditingController _phone;
  String _breed = '';
  String _gender = 'mužjak';
  String _size = 'srednji';
  String _city = 'Novi Sad';
  String _neighborhood = 'Liman 1';
  bool _vaccinated = true;
  bool _sterilized = false;
  bool _saving = false;
  final List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _name = TextEditingController();
    _customBreed = TextEditingController();
    _age = TextEditingController();
    _story = TextEditingController();
    _phone = TextEditingController();
    _city = _initialCity(profile.ownerLocation);
    final hoods = SerbiaLocations.neighborhoodsForAdoptionCity(_city);
    _neighborhood = _matchingNeighborhood(profile.ownerLocation, hoods);
  }

  @override
  void dispose() {
    _name.dispose();
    _customBreed.dispose();
    _age.dispose();
    _story.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AdoptionStrings.addTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: AdoptionStrings.name,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AdoptionStrings.nameRequired;
                }
                return ContentValidationService.validateText(value);
              },
            ),
            SizedBox(height: 12),
            BreedField(
              breed: _breed,
              customBreedController: _customBreed,
              onBreedChanged: (value) => setState(() => _breed = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AdoptionStrings.breedRequired;
                }
                final text = _breed.trim();
                if (text.isEmpty) {
                  return AdoptionStrings.breedRequired;
                }
                return ContentValidationService.validateText(text);
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _age,
              decoration: InputDecoration(
                labelText: AdoptionStrings.age,
                hintText: AdoptionStrings.ageHint,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AdoptionStrings.ageRequired;
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _SectionLabel(AdoptionStrings.gender),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ChoiceChip(
                  label: AdoptionStrings.male,
                  icon: Icons.male_rounded,
                  selected: _gender == 'mužjak',
                  onTap: () => setState(() => _gender = 'mužjak'),
                ),
                _ChoiceChip(
                  label: AdoptionStrings.female,
                  icon: Icons.female_rounded,
                  selected: _gender == 'ženka',
                  onTap: () => setState(() => _gender = 'ženka'),
                ),
              ],
            ),
            SizedBox(height: 16),
            _SectionLabel(AdoptionStrings.size),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ChoiceChip(
                  label: AdoptionStrings.sizeSmall,
                  selected: _size == 'mali',
                  onTap: () => setState(() => _size = 'mali'),
                ),
                _ChoiceChip(
                  label: AdoptionStrings.sizeMedium,
                  selected: _size == 'srednji',
                  onTap: () => setState(() => _size = 'srednji'),
                ),
                _ChoiceChip(
                  label: AdoptionStrings.sizeLarge,
                  selected: _size == 'veliki',
                  onTap: () => setState(() => _size = 'veliki'),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _story,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: AdoptionStrings.story,
                hintText: AdoptionStrings.storyHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AdoptionStrings.storyRequired;
                }
                return ContentValidationService.validateText(value);
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('adoption-city'),
              initialValue: _city,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AdoptionStrings.city,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final city in SerbiaLocations.adoptionCities)
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _city = value;
                  final hoods =
                      SerbiaLocations.neighborhoodsForAdoptionCity(value);
                  _neighborhood = hoods.contains(_neighborhood)
                      ? _neighborhood
                      : hoods.first;
                });
              },
              validator: (value) =>
                  value == null || value.isEmpty
                      ? AdoptionStrings.cityRequired
                      : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('adoption-hood-$_city-$_neighborhood'),
              initialValue: SerbiaLocations.neighborhoodsForAdoptionCity(_city)
                      .contains(_neighborhood)
                  ? _neighborhood
                  : SerbiaLocations.neighborhoodsForAdoptionCity(_city).first,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AdoptionStrings.neighborhood,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final hood
                    in SerbiaLocations.neighborhoodsForAdoptionCity(_city))
                  DropdownMenuItem(value: hood, child: Text(hood)),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _neighborhood = value);
              },
              validator: (value) =>
                  value == null || value.isEmpty
                      ? AdoptionStrings.neighborhoodRequired
                      : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AdoptionStrings.phone,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? AdoptionStrings.phoneRequired
                      : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdoptionStrings.vaccinated),
              activeThumbColor: AppColors.onPrimary,
              activeTrackColor: AppColors.primary,
              value: _vaccinated,
              onChanged: (value) => setState(() => _vaccinated = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdoptionStrings.sterilized),
              activeThumbColor: AppColors.onPrimary,
              activeTrackColor: AppColors.primary,
              value: _sterilized,
              onChanged: (value) => setState(() => _sterilized = value),
            ),
            SizedBox(height: 8),
            _SectionLabel(AdoptionStrings.addPhotos),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed:
                        _saving ? null : () => _pickPhotos(ImageSource.gallery),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primaryDeep,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      '${AdoptionStrings.addPhotos} (${_photos.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed:
                      _saving ? null : () => _pickPhotos(ImageSource.camera),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primaryDeep,
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.photo_camera_outlined),
                ),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FutureBuilder(
                        future: _photos[index].readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const ColoredBox(
                              color: Color(0xFF2A2D3E),
                              child: SizedBox(
                                width: 88,
                                height: 88,
                                child: Icon(Icons.image, color: Colors.white70),
                              ),
                            );
                          }
                          return Image.memory(
                            snapshot.data!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox.shrink()
                  : const Icon(Icons.campaign_outlined),
              label: _saving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(AdoptionStrings.publishing),
                      ],
                    )
                  : Text(AdoptionStrings.publish),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos(ImageSource source) async {
    final picker = ImagePicker();
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      picked = file == null ? const [] : [file];
    } else {
      picked = await picker.pickMultiImage(imageQuality: 85);
    }
    if (picked.isEmpty) {
      return;
    }
    for (final file in picked) {
      final error = await ContentValidationService.validateImage(file);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
        continue;
      }
      setState(() => _photos.add(file));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref.read(adoptionControllerProvider.notifier).publish(
            name: _name.text.trim(),
            breed: _breed.trim(),
            age: _age.text.trim(),
            gender: _gender,
            size: _size,
            city: _city,
            neighborhood: _neighborhood,
            description: _story.text.trim(),
            contactPhone: _phone.text.trim(),
            isVaccinated: _vaccinated,
            isSterilized: _sterilized,
            photos: List<XFile>.from(_photos),
          );
      if (!mounted) {
        return;
      }
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdoptionStrings.publishError)),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          e,
          fallback: AdoptionStrings.publishError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _initialCity(String rawLocation) {
    final sanitized = SerbiaLocations.sanitizeLocationLabel(rawLocation);
    for (final city in SerbiaLocations.adoptionCities) {
      if (sanitized.toLowerCase().startsWith(city.toLowerCase())) {
        return city;
      }
    }
    final homeName = ref.read(homeCityProvider)?.name;
    if (homeName != null && SerbiaLocations.adoptionCities.contains(homeName)) {
      return homeName;
    }
    return 'Novi Sad';
  }

  String _matchingNeighborhood(String rawLocation, List<String> hoods) {
    if (hoods.isEmpty) {
      return '';
    }
    final sanitized = SerbiaLocations.sanitizeLocationLabel(rawLocation);
    var rest = sanitized.contains(',')
        ? sanitized.substring(sanitized.indexOf(',') + 1).trim()
        : '';
    if (rest.isEmpty) {
      return hoods.first;
    }
    final needle = rest.toLowerCase();
    for (final hood in hoods) {
      if (hood.toLowerCase() == needle) {
        return hood;
      }
    }
    for (final hood in hoods) {
      final lower = hood.toLowerCase();
      if (lower.startsWith(needle)) {
        return hood;
      }
    }
    return hoods.first;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.lightOnBackground,
          ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.primarySoft;
    final fg = selected ? AppColors.onPrimary : AppColors.primaryDeep;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
              width: selected ? 0 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
