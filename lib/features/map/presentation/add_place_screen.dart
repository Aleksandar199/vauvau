import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/address_geocoder.dart';
import '../data/places_repository.dart';
import '../domain/city_model.dart';
import 'cities_controller.dart';
import 'map_strings.dart';

/// Admin-only place creation with address search + pin fine-tuning.
class AddPlaceScreen extends ConsumerStatefulWidget {
  const AddPlaceScreen({super.key, this.initialCityId});

  final String? initialCityId;

  @override
  ConsumerState<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends ConsumerState<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  final _phone = TextEditingController();
  final _mapController = MapController();
  final _geocoder = AddressGeocoder();

  String _category = 'pet_shop';
  CityModel? _city;
  LatLng? _pin;
  List<GeocodeSuggestion> _suggestions = const [];
  var _searching = false;
  var _saving = false;
  String? _error;

  static const _categories = <(String, String)>[
    ('pet_shop', 'Pet Shop'),
    ('park', 'Park za pse'),
    ('vet', 'Veterinar'),
    ('cafe', 'Kafić prijatelj pasa'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _hours.dispose();
    _phone.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final cities = ref.watch(citiesProvider).asData?.value ?? SeedCities.all;
    final city = _city ?? _resolveInitialCity(cities);
    final pin = _pin ?? LatLng(city.latitude, city.longitude);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text(MapStrings.addPlaceAdminTitle)),
        body: const Center(child: Text(MapStrings.adminOnlyPlace)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(MapStrings.addPlaceAdminTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: MapStrings.placeCategory,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final item in _categories)
                  DropdownMenuItem(value: item.$1, child: Text(item.$2)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _category = value);
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: city.id,
              decoration: const InputDecoration(
                labelText: MapStrings.placeCity,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final item in cities)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      final match = cities.where((c) => c.id == value);
                      if (match.isEmpty) return;
                      final next = match.first;
                      setState(() {
                        _city = next;
                        _pin = LatLng(next.latitude, next.longitude);
                      });
                      _mapController.move(_pin!, 14);
                    },
              validator: (value) =>
                  value == null ? MapStrings.placeCityRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: MapStrings.placeAddressSearch,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: MapStrings.searchAddress,
                  onPressed: _saving || _searching ? null : _searchAddress,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return MapStrings.placeAddressRequired;
                }
                return ContentValidationService.validateText(value);
              },
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._suggestions.map(
                (suggestion) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    suggestion.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _address.text = suggestion.label;
                      _pin = LatLng(
                        suggestion.latitude,
                        suggestion.longitude,
                      );
                      _suggestions = const [];
                    });
                    _mapController.move(_pin!, 16);
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _hours,
              decoration: const InputDecoration(
                labelText: MapStrings.openingHoursOptional,
                hintText: MapStrings.openingHoursHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: MapStrings.placePhone,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              MapStrings.fineTuneLocation,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              MapStrings.fineTuneLocationHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: pin,
                    initialZoom: 14,
                    onTap: (_, point) => setState(() => _pin = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vauvau.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pin,
                          width: 40,
                          height: 40,
                          alignment: Alignment.bottomCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFDC2626),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${MapStrings.coordinates}: '
              '${pin.latitude.toStringAsFixed(5)}, '
              '${pin.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(MapStrings.submitPlace),
            ),
          ],
        ),
      ),
    );
  }

  CityModel _resolveInitialCity(List<CityModel> cities) {
    final initialId = widget.initialCityId;
    if (initialId != null) {
      for (final city in cities) {
        if (city.id == initialId) return city;
      }
    }
    final selected = ref.read(mapRegionProvider);
    if (!selected.isMyLocation && selected.city != null) {
      return selected.city!;
    }
    return cities.isNotEmpty ? cities.first : SeedCities.noviSad;
  }

  Future<void> _searchAddress() async {
    setState(() {
      _searching = true;
      _error = null;
      _suggestions = const [];
    });
    try {
      final cities =
          ref.read(citiesProvider).asData?.value ?? SeedCities.all;
      final city = _city ?? _resolveInitialCity(cities);
      final query = [
        _address.text.trim(),
        city.name,
        'Srbija',
      ].where((part) => part.isNotEmpty).join(', ');
      final results = await _geocoder.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        if (results.isEmpty) {
          _error = MapStrings.addressNotFound;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = MapStrings.addressSearchFailed;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cities =
        ref.read(citiesProvider).asData?.value ?? SeedCities.all;
    final city = _city ?? _resolveInitialCity(cities);
    final pin = _pin ?? LatLng(city.latitude, city.longitude);
    final uid = FirebaseAuth.instance.currentUser?.uid ??
        ref.read(authStateProvider).asData?.value?.uid ??
        '';
    if (uid.isEmpty) {
      setState(() => _error = MapStrings.adminOnlyPlace);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(placesRepositoryProvider).createPlace(
            PlaceDraft(
              name: _name.text.trim(),
              category: _category,
              cityId: city.id,
              cityName: city.name,
              address: _address.text.trim(),
              latitude: pin.latitude,
              longitude: pin.longitude,
              openingHours: _hours.text.trim(),
              phone: _phone.text.trim(),
              createdBy: uid,
            ),
          );
      ref.invalidate(livePlacesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(MapStrings.placeAdded),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      debugPrint('Add place failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = MapStrings.placeAddFailed;
      });
    }
  }
}

/// Opens [AddPlaceScreen] for admins; no-ops for regular users.
Future<bool> openAddPlaceScreen(
  BuildContext context,
  WidgetRef ref, {
  String? initialCityId,
}) async {
  if (!ref.read(isAdminProvider)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(MapStrings.adminOnlyPlace)),
    );
    return false;
  }
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => AddPlaceScreen(initialCityId: initialCityId),
    ),
  );
  return result ?? false;
}
