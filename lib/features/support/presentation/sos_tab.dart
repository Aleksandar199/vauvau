import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/utils/external_link_launcher.dart';
import '../../adoption/presentation/phone_launcher.dart';
import '../../location/presentation/home_city_provider.dart';
import '../domain/sos_contacts.dart';
import 'support_strings.dart';

/// SOS contacts for one city at a time: city chips on top (default = the
/// user's home city, else the first city), contacts grouped by
/// [SosContactKind]. All numbers live in [SosContacts].
class SosTab extends ConsumerStatefulWidget {
  const SosTab({super.key});

  @override
  ConsumerState<SosTab> createState() => _SosTabState();
}

class _SosTabState extends ConsumerState<SosTab> {
  String? _pickedCityId;

  String _defaultCityId() {
    final homeId = ref.watch(homeCityProvider)?.id;
    final known = SerbiaLocations.cities.any((c) => c.id == homeId);
    return known ? homeId! : SerbiaLocations.cities.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityId = _pickedCityId ?? _defaultCityId();
    final groups = SosContacts.groupedForCity(cityId);
    final checked = SosContacts.checkedOn;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SosHeader(),
            const SizedBox(height: 14),
            _CityPicker(
              selectedId: cityId,
              onSelected: (id) => setState(() => _pickedCityId = id),
            ),
            const SizedBox(height: 14),
            if (groups.isEmpty)
              _SosNotice(text: SupportStrings.sosNoContacts)
            else ...[
              if (!groups.containsKey(SosContactKind.emergencyVet))
                _SosNotice(text: SupportStrings.sosNo24h),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text(
                    _groupLabel(entry.key),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final contact in entry.value)
                  _SosEmergencyCard(
                    contact: contact,
                    onCall: (phone) => _call(phone),
                    onOpen: (uri) => _open(uri),
                  ),
              ],
            ],
            const SizedBox(height: 6),
            Text(
              SupportStrings.sosCheckedOn(
                '${checked.day}. ${checked.month}. ${checked.year}.',
              ),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call(SosPhone phone) async {
    final ok = await ref.read(phoneLauncherProvider).call(phone.dialable);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupportStrings.callUnavailable)),
      );
    }
  }

  Future<void> _open(Uri uri) async {
    var ok = false;
    try {
      ok = await ref.read(externalLinkLauncherProvider).open(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupportStrings.linkError)),
      );
    }
  }
}

String _groupLabel(SosContactKind kind) => switch (kind) {
      SosContactKind.emergencyVet => SupportStrings.sosGroupEmergencyVet,
      SosContactKind.vetClinic => SupportStrings.sosGroupVetClinic,
      SosContactKind.animalControl => SupportStrings.sosGroupAnimalControl,
      SosContactKind.other => SupportStrings.sosGroupOther,
    };

String _kindLabel(SosContactKind kind) => switch (kind) {
      SosContactKind.emergencyVet ||
      SosContactKind.vetClinic =>
        SupportStrings.sosVet,
      SosContactKind.animalControl => SupportStrings.sosShelter,
      SosContactKind.other => SupportStrings.sosLocal,
    };

IconData _kindIcon(SosContactKind kind) => switch (kind) {
      SosContactKind.emergencyVet ||
      SosContactKind.vetClinic =>
        Icons.local_hospital_outlined,
      SosContactKind.animalControl => Icons.pets_outlined,
      SosContactKind.other => Icons.emergency_outlined,
    };

class _CityPicker extends StatelessWidget {
  const _CityPicker({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final city in SerbiaLocations.cities)
          ChoiceChip(
            key: ValueKey('sos-city-${city.id}'),
            label: Text(city.name),
            selected: city.id == selectedId,
            selectedColor: Colors.red.shade100,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: city.id == selectedId ? Colors.red.shade800 : null,
            ),
            onSelected: (_) => onSelected(city.id),
          ),
      ],
    );
  }
}

class _SosNotice extends StatelessWidget {
  const _SosNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosHeader extends StatelessWidget {
  const _SosHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            SupportStrings.sosBadge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          SupportStrings.sosSubtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          SupportStrings.sosIntro,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _SosEmergencyCard extends StatelessWidget {
  const _SosEmergencyCard({
    required this.contact,
    required this.onCall,
    required this.onOpen,
  });

  final SosContact contact;
  final ValueChanged<SosPhone> onCall;
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final primary = contact.primaryPhone;
    final extraPhones = contact.phones.skip(1).toList();
    final mapsUri = contact.mapsUri;
    final websiteUri = contact.websiteUri;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.red.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _kindIcon(contact.kind),
                        color: Colors.red.shade700,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _kindLabel(contact.kind),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          primary.label == null
                              ? primary.number
                              : '${primary.number} · ${primary.label}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton.filled(
                      tooltip: '${SupportStrings.callNow} ${primary.number}',
                      onPressed: () => onCall(primary),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.phone_in_talk, size: 20),
                    ),
                  ),
                ],
              ),
              if (contact.note != null) ...[
                const SizedBox(height: 8),
                Text(
                  contact.note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
              if (contact.address != null) ...[
                const SizedBox(height: 4),
                Text(
                  contact.address!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
              if (extraPhones.isNotEmpty ||
                  mapsUri != null ||
                  websiteUri != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final phone in extraPhones)
                      _CardAction(
                        icon: Icons.phone_outlined,
                        label: phone.label == null
                            ? phone.number
                            : '${phone.number} · ${phone.label}',
                        onTap: () => onCall(phone),
                      ),
                    if (mapsUri != null)
                      _CardAction(
                        icon: Icons.directions_outlined,
                        label: SupportStrings.sosNavigate,
                        onTap: () => onOpen(mapsUri),
                      ),
                    if (websiteUri != null)
                      _CardAction(
                        icon: Icons.open_in_new,
                        label: SupportStrings.sosWebsite,
                        onTap: () => onOpen(websiteUri),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Colors.red.shade700;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
