import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adoption/presentation/phone_launcher.dart';
import 'support_strings.dart';

class SosTab extends ConsumerWidget {
  const SosTab({super.key});

  static const _contacts = <_SosContact>[
    _SosContact(
      city: 'Novi Sad',
      title: 'NS VET (00–24h)',
      phone: '021 493 007\n063 590 192',
      address: 'Novi Sad',
      kind: _SosKind.vet,
    ),
    _SosContact(
      city: 'Novi Sad',
      title: 'Milenium Vet (00–24h)',
      phone: '065 474 9212',
      address: 'Novi Sad',
      kind: _SosKind.vet,
    ),
    _SosContact(
      city: 'Novi Sad',
      title: 'JKP Zoohigijena i Veterina Novi Sad',
      phone: '021 640 3220',
      address: 'Novi Sad',
      kind: _SosKind.shelter,
    ),
    _SosContact(
      city: 'Novi Sad',
      title: 'Ambulanta Futoški put',
      phone: '021 403 402',
      address: 'Futoški put, Novi Sad',
      kind: _SosKind.local,
    ),
    _SosContact(
      city: 'Beograd',
      title: 'Vet Planet Klinika (00–24h)',
      phone: '011 7707 227\n065 3565 664',
      address: 'Beograd',
      kind: _SosKind.vet,
    ),
    _SosContact(
      city: 'Beograd',
      title: 'Vet Urgent (00–24h)',
      phone: '011 2461 383\n063 342 235',
      address: 'Beograd',
      kind: _SosKind.vet,
    ),
    _SosContact(
      city: 'Beograd',
      title: 'JKP Veterina Beograd (Zoohigijena)',
      phone: '011 329 3099\n063 549 161',
      address: 'Beograd',
      kind: _SosKind.shelter,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
            const SizedBox(height: 18),
            for (var i = 0; i < _contacts.length; i++) ...[
              if (i == 0 || _contacts[i].city != _contacts[i - 1].city)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10, bottom: 8),
                  child: Text(
                    _contacts[i].city,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              _SosEmergencyCard(
                contact: _contacts[i],
                onCall: () => _call(context, ref, _contacts[i].phone),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _call(
    BuildContext context,
    WidgetRef ref,
    String phone,
  ) async {
    final ok = await ref.read(phoneLauncherProvider).call(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(SupportStrings.callUnavailable)),
      );
    }
  }
}

enum _SosKind { vet, shelter, local }

class _SosContact {
  const _SosContact({
    required this.city,
    required this.title,
    required this.phone,
    required this.address,
    required this.kind,
  });

  final String city;
  final String title;
  final String phone;
  final String address;
  final _SosKind kind;

  String get kindLabel => switch (kind) {
        _SosKind.vet => SupportStrings.sosVet,
        _SosKind.shelter => SupportStrings.sosShelter,
        _SosKind.local => SupportStrings.sosLocal,
      };

  IconData get icon => switch (kind) {
        _SosKind.vet => Icons.local_hospital_outlined,
        _SosKind.shelter => Icons.pets_outlined,
        _SosKind.local => Icons.emergency_outlined,
      };

  String get primaryPhone => phone.split('\n').first.trim();
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
        const SizedBox(height: 8),
        Text(
          SupportStrings.sosSubtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
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
  });

  final _SosContact contact;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
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
          child: Row(
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
                  contact.icon,
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
                    contact.kindLabel,
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
                    contact.title,
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
                    contact.primaryPhone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (contact.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                onPressed: onCall,
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
        ),
      ),
    );
  }
}
