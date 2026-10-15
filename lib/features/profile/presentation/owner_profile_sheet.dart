import 'package:flutter/material.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../data/owner_public_profile.dart';
import 'profile_strings.dart';

typedef OwnerProfileLoader =
    Future<OwnerPublicProfile?> Function(String userId);

/// Opens the public profile of the person [userId] (e.g. from the avatar
/// next to a chat message). Until / unless Firestore answers, the sheet shows
/// the fallback name, avatar and dogs the caller already has.
Future<void> showOwnerProfileSheet(
  BuildContext context, {
  required String userId,
  String fallbackName = '',
  String fallbackAvatarUrl = '',
  List<DiscoverProfile> fallbackDogs = const [],
  OwnerProfileLoader loader = loadOwnerPublicProfile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => OwnerProfileSheet(
      userId: userId,
      fallbackName: fallbackName,
      fallbackAvatarUrl: fallbackAvatarUrl,
      fallbackDogs: fallbackDogs,
      loader: loader,
    ),
  );
}

class OwnerProfileSheet extends StatefulWidget {
  const OwnerProfileSheet({
    super.key,
    required this.userId,
    this.fallbackName = '',
    this.fallbackAvatarUrl = '',
    this.fallbackDogs = const [],
    this.loader = loadOwnerPublicProfile,
  });

  final String userId;
  final String fallbackName;
  final String fallbackAvatarUrl;
  final List<DiscoverProfile> fallbackDogs;
  final OwnerProfileLoader loader;

  @override
  State<OwnerProfileSheet> createState() => _OwnerProfileSheetState();
}

class _OwnerProfileSheetState extends State<OwnerProfileSheet> {
  late final Future<OwnerPublicProfile?> _profile = _load();

  Future<OwnerPublicProfile?> _load() async {
    try {
      return await widget.loader(widget.userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OwnerPublicProfile?>(
      future: _profile,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        final name = (loaded?.name.isNotEmpty ?? false)
            ? loaded!.name
            : widget.fallbackName.trim();
        final photo = (loaded?.photoUrl.isNotEmpty ?? false)
            ? loaded!.photoUrl
            : widget.fallbackAvatarUrl.trim();
        final dogs = (loaded?.dogs.isNotEmpty ?? false)
            ? loaded!.dogs
            : widget.fallbackDogs;
        return _OwnerProfileBody(
          name: name.isEmpty ? ProfileStrings.ownerUnknown : name,
          photoUrl: photo,
          location: loaded?.location ?? '',
          bio: loaded?.bio ?? '',
          dogs: dogs,
          loading: loading,
        );
      },
    );
  }
}

class _OwnerProfileBody extends StatelessWidget {
  const _OwnerProfileBody({
    required this.name,
    required this.photoUrl,
    required this.location,
    required this.bio,
    required this.dogs,
    required this.loading,
  });

  final String name;
  final String photoUrl;
  final String location;
  final String bio;
  final List<DiscoverProfile> dogs;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          key: const ValueKey('owner-profile-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Center(
              child: _Avatar(url: photoUrl, name: name, size: 96),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(bio, textAlign: TextAlign.center),
            ],
            if (loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
            if (dogs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                ProfileStrings.ownerDogs,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              for (final dog in dogs)
                ListTile(
                  key: ValueKey('owner-dog-${dog.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: _Avatar(
                    url: dog.photoUrls.isEmpty ? '' : dog.photoUrls.first,
                    name: dog.name,
                    size: 48,
                  ),
                  title: Text(dog.name),
                  subtitle: dog.breed.trim().isEmpty ? null : Text(dog.breed),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DogDetailSheet(profile: dog),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.size});

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.trim().isEmpty
            ? ColoredBox(
                color: AppColors.primarySoft,
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.4,
                    ),
                  ),
                ),
              )
            : buildDogImage(url, seed: url, width: size, height: size),
      ),
    );
  }
}
