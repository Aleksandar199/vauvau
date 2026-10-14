import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/content_validation_service.dart';
import '../../../location/presentation/location_controller.dart';
import '../../domain/map_city.dart';
import '../../domain/models/poi_model.dart';
import '../map_strings.dart';
import '../user_poi_controller.dart';

Future<void> showAddPoiSheet(
  BuildContext context,
  WidgetRef ref, {
  MapCity initialCity = MapCity.noviSad,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: AddPoiSheet(initialCity: initialCity),
      );
    },
  );
}

class AddPoiSheet extends ConsumerStatefulWidget {
  const AddPoiSheet({super.key, this.initialCity = MapCity.noviSad});

  final MapCity initialCity;

  @override
  ConsumerState<AddPoiSheet> createState() => _AddPoiSheetState();
}

class _AddPoiSheetState extends ConsumerState<AddPoiSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _price;
  PoiCategory _category = PoiCategory.cafe;
  late MapCity _city;
  bool _is24_7 = false;
  bool _emergency = false;
  bool _overnight = false;
  bool _dayCare = false;
  bool _hasYard = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _address = TextEditingController();
    _phone = TextEditingController();
    _price = TextEditingController();
    _city = widget.initialCity;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MapStrings.addPlace,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: MapStrings.placeName,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return MapStrings.placeNameRequired;
                }
                return ContentValidationService.validateTitle(value);
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<PoiCategory>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: MapStrings.placeCategory,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in PoiCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.submitLabel),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<MapCity>(
              initialValue: _city,
              decoration: InputDecoration(
                labelText: MapStrings.placeCity,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final city in MapCity.values)
                  DropdownMenuItem(
                    value: city,
                    child: Text(city.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _city = value);
                }
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: MapStrings.placeAddress,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return MapStrings.placeAddressRequired;
                }
                return ContentValidationService.validateText(value);
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: MapStrings.placePhone,
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(MapStrings.toggle24h),
              value: _is24_7,
              onChanged: (value) => setState(() => _is24_7 = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(MapStrings.toggleEmergency),
              value: _emergency,
              onChanged: (value) => setState(() => _emergency = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(MapStrings.toggleOvernight),
              value: _overnight,
              onChanged: (value) => setState(() => _overnight = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(MapStrings.toggleDayCare),
              value: _dayCare,
              onChanged: (value) => setState(() => _dayCare = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(MapStrings.toggleYard),
              value: _hasYard,
              onChanged: (value) => setState(() => _hasYard = value),
            ),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: MapStrings.pricePerNight,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(MapStrings.submitPlace),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final location = ref.read(userLocationProvider);
    final parsedPrice = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    final camera = _city.camera;
    final latitude = camera?.latitude ?? location.latitude;
    final longitude = camera?.longitude ?? location.longitude;
    ref.read(userPoiSubmissionsProvider.notifier).add(
          PoiModel(
            id: 'user-${DateTime.now().millisecondsSinceEpoch}',
            name: _name.text.trim(),
            category: _category,
            address: _address.text.trim(),
            latitude: latitude,
            longitude: longitude,
            phone: _phone.text.trim(),
            is24_7: _is24_7,
            isEmergencyService: _emergency,
            overnightStay: _overnight,
            dayCare: _dayCare,
            hasYard: _hasYard,
            pricePerNight: parsedPrice,
            city: _city,
            verificationStatus: PoiVerificationStatus.pending,
            lastVerified: DateTime.now(),
            source: MapStrings.userSource,
          ),
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(MapStrings.placeAdded)),
    );
  }
}

extension PoiCategorySubmitLabel on PoiCategory {
  String get submitLabel => switch (this) {
        PoiCategory.cafe => MapStrings.cafe,
        PoiCategory.restaurant => MapStrings.restaurant,
        PoiCategory.park => MapStrings.park,
        PoiCategory.petShop => MapStrings.petShop,
        PoiCategory.groomer => MapStrings.groomer,
        PoiCategory.vet => MapStrings.vet,
        PoiCategory.lodging => MapStrings.lodging,
        PoiCategory.training => MapStrings.training,
        PoiCategory.dogHotel => MapStrings.dogHotel,
        PoiCategory.selfWash => MapStrings.selfWash,
        PoiCategory.dogTreats => MapStrings.dogTreats,
        PoiCategory.shelter => MapStrings.shelter,
        PoiCategory.water => MapStrings.waterForDogs,
        PoiCategory.petSitter => MapStrings.petSitter,
        PoiCategory.other => MapStrings.otherPlace,
      };
}
