import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../adoption/presentation/adoption_strings.dart';
import '../domain/lost_dog.dart';
import 'lost_dog_strings.dart';
import 'lost_dogs_controller.dart';

Future<String?> showReportCaseChooser(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LostDogStrings.chooseTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () =>
                    Navigator.of(sheetContext).pop(LostDogType.lost),
                child: const Text(LostDogStrings.reportLost),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () =>
                    Navigator.of(sheetContext).pop(LostDogType.found),
                child: const Text(LostDogStrings.reportFound),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool?> showReportLostDogSheet(
  BuildContext context, {
  String type = LostDogType.lost,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.92;
      return SizedBox(
        height: height,
        child: ReportLostDogSheet(type: type),
      );
    },
  );
}

class ReportLostDogSheet extends ConsumerStatefulWidget {
  const ReportLostDogSheet({super.key, this.type = LostDogType.lost});

  final String type;

  @override
  ConsumerState<ReportLostDogSheet> createState() => _ReportLostDogSheetState();
}

class _ReportLostDogSheetState extends ConsumerState<ReportLostDogSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _phone;
  late final TextEditingController _breedOther;
  String _city = 'Novi Sad';
  String _neighborhood = 'Liman 1';
  String _breed = LostDogStrings.breedUnknown;
  DateTime _eventDate = DateTime.now();
  XFile? _photo;
  var _saving = false;

  bool get _isFound => widget.type == LostDogType.found;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _description = TextEditingController();
    _phone = TextEditingController();
    _breedOther = TextEditingController();
    final hoods = SerbiaLocations.neighborhoodsForAdoptionCity(_city);
    _neighborhood = hoods.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _phone.dispose();
    _breedOther.dispose();
    super.dispose();
  }

  String get _resolvedBreed {
    if (_breed == LostDogStrings.breedOther) {
      return _breedOther.text.trim();
    }
    return _breed;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isFound ? const Color(0xFF43A047) : Colors.redAccent;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFound ? LostDogStrings.addFoundTitle : LostDogStrings.addTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _isFound
                    ? LostDogStrings.dogNameOptional
                    : LostDogStrings.dogName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isFound) {
                  return value == null || value.trim().isEmpty
                      ? null
                      : ContentValidationService.validateText(value);
                }
                if (value == null || value.trim().isEmpty) {
                  return LostDogStrings.dogNameRequired;
                }
                return ContentValidationService.validateText(value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _breed,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: LostDogStrings.breed,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final breed in LostDogStrings.breedOptions)
                  DropdownMenuItem(value: breed, child: Text(breed)),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _breed = value);
              },
            ),
            if (_breed == LostDogStrings.breedOther) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedOther,
                decoration: const InputDecoration(
                  labelText: LostDogStrings.breedHint,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LostDogStrings.breedRequired;
                  }
                  return ContentValidationService.validateText(value);
                },
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _city,
              isExpanded: true,
              decoration: const InputDecoration(
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
                  _neighborhood = hoods.first;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('lost-hood-$_city-$_neighborhood'),
              initialValue: _neighborhood,
              isExpanded: true,
              decoration: const InputDecoration(
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
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _isFound ? LostDogStrings.foundDate : LostDogStrings.lostDate,
              ),
              subtitle: Text(LostDogStrings.formatDate(_eventDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: LostDogStrings.description,
                hintText: _isFound
                    ? LostDogStrings.foundDescriptionHint
                    : LostDogStrings.descriptionHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return LostDogStrings.descriptionRequired;
                }
                return ContentValidationService.validateText(value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: LostDogStrings.phone,
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? LostDogStrings.phoneRequired
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _photo == null
                    ? LostDogStrings.addPhoto
                    : LostDogStrings.photo,
              ),
            ),
            if (_photo != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder(
                    future: _photo!.readAsBytes(),
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
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const Text(LostDogStrings.publishing)
                  : Text(
                      _isFound
                          ? LostDogStrings.publishFound
                          : LostDogStrings.publish,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    final error = await ContentValidationService.validateImage(file);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _photo = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isFound && _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(LostDogStrings.photoRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final ok = await ref.read(lostDogsControllerProvider.notifier).report(
            dogName: name.isEmpty ? LostDogStrings.unknownName : name,
            city: _city,
            neighborhood: _neighborhood,
            eventDate: _eventDate,
            description: _description.text.trim(),
            contactPhone: _phone.text.trim(),
            type: widget.type,
            breed: _resolvedBreed.isEmpty
                ? LostDogStrings.breedUnknown
                : _resolvedBreed,
            photo: _photo,
          );
      if (!mounted) {
        return;
      }
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(LostDogStrings.publishError)),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          e,
          fallback: LostDogStrings.publishError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
