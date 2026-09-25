import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/content_validation_service.dart';
import '../../../discover/presentation/widgets/discover_filter_chip.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../adoption_controller.dart';
import '../adoption_strings.dart';

class AddAdoptionDogScreen extends ConsumerStatefulWidget {
  const AddAdoptionDogScreen({super.key});

  @override
  ConsumerState<AddAdoptionDogScreen> createState() =>
      _AddAdoptionDogScreenState();
}

class _AddAdoptionDogScreenState extends ConsumerState<AddAdoptionDogScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _age;
  late final TextEditingController _story;
  late final TextEditingController _location;
  late final TextEditingController _phone;
  String _gender = 'mužjak';
  String _size = 'srednji';
  bool _vaccinated = true;
  bool _sterilized = false;
  bool _saving = false;
  final List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _name = TextEditingController();
    _breed = TextEditingController();
    _age = TextEditingController();
    _story = TextEditingController();
    _location = TextEditingController(text: profile.ownerLocation);
    _phone = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _story.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AdoptionStrings.addTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _breed,
              decoration: const InputDecoration(
                labelText: AdoptionStrings.breed,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              decoration: const InputDecoration(
                labelText: AdoptionStrings.age,
                hintText: AdoptionStrings.ageHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(AdoptionStrings.gender),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                DiscoverFilterChip(
                  label: AdoptionStrings.male,
                  selected: _gender == 'mužjak',
                  onTap: () => setState(() => _gender = 'mužjak'),
                ),
                DiscoverFilterChip(
                  label: AdoptionStrings.female,
                  selected: _gender == 'ženka',
                  onTap: () => setState(() => _gender = 'ženka'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(AdoptionStrings.size),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                DiscoverFilterChip(
                  label: AdoptionStrings.sizeSmall,
                  selected: _size == 'mali',
                  onTap: () => setState(() => _size = 'mali'),
                ),
                DiscoverFilterChip(
                  label: AdoptionStrings.sizeMedium,
                  selected: _size == 'srednji',
                  onTap: () => setState(() => _size = 'srednji'),
                ),
                DiscoverFilterChip(
                  label: AdoptionStrings.sizeLarge,
                  selected: _size == 'veliki',
                  onTap: () => setState(() => _size = 'veliki'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _story,
              maxLines: 5,
              decoration: const InputDecoration(
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: AdoptionStrings.location,
                hintText: AdoptionStrings.locationHint,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? AdoptionStrings.locationRequired
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
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
              title: const Text(AdoptionStrings.vaccinated),
              value: _vaccinated,
              onChanged: (value) => setState(() => _vaccinated = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AdoptionStrings.sterilized),
              value: _sterilized,
              onChanged: (value) => setState(() => _sterilized = value),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text('${AdoptionStrings.addPhotos} (${_photos.length})'),
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
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : _publish,
              child: Text(
                _saving ? '...' : AdoptionStrings.publish,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
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
    final ok = await ref.read(adoptionControllerProvider.notifier).publish(
          name: _name.text.trim(),
          breed: _breed.text.trim().isEmpty ? 'Mešanac' : _breed.text.trim(),
          age: _age.text.trim().isEmpty ? '—' : _age.text.trim(),
          gender: _gender,
          size: _size,
          location: _location.text.trim(),
          description: _story.text.trim(),
          contactPhone: _phone.text.trim(),
          isVaccinated: _vaccinated,
          isSterilized: _sterilized,
          photos: List<XFile>.from(_photos),
        );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AdoptionStrings.publishError)),
      );
    }
  }
}
