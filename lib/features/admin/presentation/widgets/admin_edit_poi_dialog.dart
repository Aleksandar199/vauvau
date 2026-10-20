import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/content_validation_service.dart';
import '../../../map/data/poi_seed_data.dart';
import '../../../map/domain/map_place.dart';
import '../../../map/domain/models/poi_model.dart';
import '../../../map/presentation/user_poi_controller.dart';
import '../admin_strings.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Result of [showAdminEditPoiDialog].
enum AdminEditPoiResult { cancelled, saved, savedAndResolved }

/// Full POI editor for admins — hours, price, address, coords, verification.
Future<AdminEditPoiResult> showAdminEditPoiDialog({
  required BuildContext context,
  required WidgetRef ref,
  required PoiModel poi,
  String? reportReason,
  String? reportDetails,
  bool offerResolve = false,
}) async {
  final result = await showAppBottomSheet<AdminEditPoiResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _AdminEditPoiSheet(
          poi: poi,
          reportReason: reportReason,
          reportDetails: reportDetails,
          offerResolve: offerResolve,
        ),
      );
    },
  );
  return result ?? AdminEditPoiResult.cancelled;
}

class _AdminEditPoiSheet extends ConsumerStatefulWidget {
  const _AdminEditPoiSheet({
    required this.poi,
    this.reportReason,
    this.reportDetails,
    this.offerResolve = false,
  });

  final PoiModel poi;
  final String? reportReason;
  final String? reportDetails;
  final bool offerResolve;

  @override
  ConsumerState<_AdminEditPoiSheet> createState() => _AdminEditPoiSheetState();
}

class _AdminEditPoiSheetState extends ConsumerState<_AdminEditPoiSheet> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _hours;
  late final TextEditingController _price;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late bool _is24_7;
  late bool _emergency;
  late bool _overnight;
  late bool _dayCare;
  late bool _hasYard;
  late bool _petFriendly;
  late bool _dogPark;
  late PoiVerificationStatus _status;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final poi = widget.poi;
    _name = TextEditingController(text: poi.name);
    _address = TextEditingController(text: poi.address);
    _phone = TextEditingController(text: poi.phone);
    _website = TextEditingController(text: poi.website ?? '');
    _hours = TextEditingController(text: poi.openingHours);
    _price = TextEditingController(
      text: poi.pricePerNight == null ? '' : poi.pricePerNight!.toString(),
    );
    _lat = TextEditingController(text: poi.latitude.toString());
    _lng = TextEditingController(text: poi.longitude.toString());
    _is24_7 = poi.is24_7;
    _emergency = poi.isEmergencyService;
    _overnight = poi.overnightStay;
    _dayCare = poi.dayCare;
    _hasYard = poi.hasYard;
    _petFriendly = poi.petFriendly;
    _dogPark = MapPlace.fromPoi(poi).isOfficialDogPark;
    _status = poi.verificationStatus;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _website.dispose();
    _hours.dispose();
    _price.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = (widget.reportReason ?? '').trim();
    final details = (widget.reportDetails ?? '').trim();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AdminStrings.editTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (reason.isNotEmpty || details.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AdminStrings.reportContextTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(details, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            TextField(
              controller: _name,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: AdminStrings.name,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _address,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: AdminStrings.address,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _hours,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: AdminStrings.openingHours,
                hintText: AdminStrings.openingHoursHint,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _price,
              enabled: !_saving,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AdminStrings.pricePerNight,
                hintText: AdminStrings.pricePerNightHint,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AdminStrings.phone,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _website,
              enabled: !_saving,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: AdminStrings.website,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lat,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AdminStrings.latitude,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lng,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AdminStrings.longitude,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<PoiVerificationStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: AdminStrings.verificationStatus,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final status in PoiVerificationStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
            SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.flag24h),
              value: _is24_7,
              onChanged:
                  _saving ? null : (v) => setState(() => _is24_7 = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.flagEmergency),
              value: _emergency,
              onChanged:
                  _saving ? null : (v) => setState(() => _emergency = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.flagOvernight),
              value: _overnight,
              onChanged:
                  _saving ? null : (v) => setState(() => _overnight = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.flagDayCare),
              value: _dayCare,
              onChanged:
                  _saving ? null : (v) => setState(() => _dayCare = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.flagYard),
              value: _hasYard,
              onChanged:
                  _saving ? null : (v) => setState(() => _hasYard = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.flagPetFriendly),
              value: _petFriendly,
              onChanged:
                  _saving ? null : (v) => setState(() => _petFriendly = v),
            ),
            if (widget.poi.category == PoiCategory.park)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AdminStrings.flagDogPark),
                value: _dogPark,
                onChanged:
                    _saving ? null : (v) => setState(() => _dogPark = v),
              ),
            const SizedBox(height: 16),
            if (widget.offerResolve)
              FilledButton(
                onPressed: _saving
                    ? null
                    : () => _save(AdminEditPoiResult.savedAndResolved),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AdminStrings.saveAndResolve),
              ),
            if (widget.offerResolve) const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed:
                  _saving ? null : () => _save(AdminEditPoiResult.saved),
              child: Text(AdminStrings.saveOnly),
            ),
            SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context)
                      .pop(AdminEditPoiResult.cancelled),
              child: Text(AdminStrings.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminEditPoiResult result) async {
    final invalid = ContentValidationService.validateTitle(_name.text) ??
        ContentValidationService.validateText(_address.text);
    if (invalid != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invalid)),
      );
      return;
    }

    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.trim().replaceAll(',', '.'));
    if (lat == null ||
        lng == null ||
        !PoiSeedData.hasValidCoordinates(
          widget.poi.copyWith(latitude: lat, longitude: lng),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminStrings.invalidCoords)),
      );
      return;
    }

    final priceRaw = _price.text.trim().replaceAll(',', '.');
    final clearPrice = priceRaw.isEmpty;
    final price = clearPrice ? null : double.tryParse(priceRaw);
    if (!clearPrice && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminStrings.invalidPrice)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final website = _website.text.trim();
      final next = widget.poi.copyWith(
        name: _name.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        website: website.isEmpty ? null : website,
        clearWebsite: website.isEmpty,
        openingHours: _hours.text.trim(),
        pricePerNight: price,
        clearPricePerNight: clearPrice,
        latitude: lat,
        longitude: lng,
        is24_7: _is24_7,
        isEmergencyService: _emergency,
        overnightStay: _overnight,
        dayCare: _dayCare,
        hasYard: _hasYard,
        petFriendly: _petFriendly,
        isDogPark: widget.poi.category == PoiCategory.park ? _dogPark : null,
        verificationStatus: _status,
        lastVerified: _status == PoiVerificationStatus.verified
            ? DateTime.now()
            : null,
      );
      await ref.read(userPoiSubmissionsProvider.notifier).updatePoi(next);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (error) {
      debugPrint('Admin POI save failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminStrings.actionFailed)),
      );
    }
  }

  String _statusLabel(PoiVerificationStatus status) {
    return switch (status) {
      PoiVerificationStatus.verified => AdminStrings.statusVerified,
      PoiVerificationStatus.pending => AdminStrings.statusPending,
      PoiVerificationStatus.userSubmitted => AdminStrings.statusSubmitted,
      PoiVerificationStatus.reported => AdminStrings.statusReported,
      PoiVerificationStatus.rejected => AdminStrings.statusRejected,
      PoiVerificationStatus.unknown => AdminStrings.statusUnknown,
    };
  }
}
