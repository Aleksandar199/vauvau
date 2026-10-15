import 'package:flutter/material.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/external_link_launcher.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../auth/domain/owner_details.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../data/owner_public_profile.dart';
import 'profile_strings.dart';

export '../data/owner_public_profile.dart' show OwnerProfileLoader;

/// Opens the public profile of the person [userId] (e.g. from the avatar
/// next to a chat message or the owner name on a Discover dog). Until /
/// unless Firestore answers, the sheet shows the fallback name, avatar and
/// dogs the caller already has.
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
  late Future<OwnerPublicProfile?> _profile = widget.loader(widget.userId);

  void _retry() {
    setState(() {
      _profile = widget.loader(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OwnerPublicProfile?>(
      future: _profile,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        final failed = !loading && snapshot.hasError;
        final name = (loaded?.name.isNotEmpty ?? false)
            ? loaded!.name
            : widget.fallbackName.trim();
        final photo = (loaded?.photoUrl.isNotEmpty ?? false)
            ? loaded!.photoUrl
            : widget.fallbackAvatarUrl.trim();
        final dogs = (loaded?.dogs.isNotEmpty ?? false)
            ? loaded!.dogs
            : widget.fallbackDogs;
        final notFound =
            !loading && !failed && loaded == null && name.isEmpty;
        return _OwnerProfileBody(
          name: name.isEmpty ? ProfileStrings.ownerUnknown : name,
          photoUrl: photo,
          location: loaded?.location ?? '',
          bio: loaded?.bio ?? '',
          details: loaded?.details ?? const OwnerDetails(),
          dogs: dogs,
          loading: loading,
          message: failed
              ? ProfileStrings.ownerProfileLoadFailed
              : (notFound ? ProfileStrings.ownerProfileUnavailable : null),
          onRetry: failed ? _retry : null,
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
    required this.details,
    required this.dogs,
    required this.loading,
    this.message,
    this.onRetry,
  });

  final String name;
  final String photoUrl;
  final String location;
  final String bio;
  final OwnerDetails details;
  final List<DiscoverProfile> dogs;
  final bool loading;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Stack(
          children: [
            ListView(
              key: const ValueKey('owner-profile-sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Center(child: _OwnerAvatar(url: photoUrl, size: 96)),
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
                      Icon(Icons.location_on_outlined, size: 16, color: muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
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
                  const Center(
                    child: CircularProgressIndicator(
                      key: ValueKey('owner-profile-loading'),
                      strokeWidth: 2,
                    ),
                  ),
                ],
                if (message != null) ...[
                  const SizedBox(height: 16),
                  _MessageBox(message: message!, onRetry: onRetry),
                ],
                ..._detailSections(details),
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
                      leading: _DogAvatar(
                        url: dog.photoUrls.isEmpty ? '' : dog.photoUrls.first,
                        name: dog.name,
                        size: 48,
                      ),
                      title: Text(dog.name),
                      subtitle: dog.breed.trim().isEmpty
                          ? null
                          : Text(dog.breed),
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
            Positioned(
              top: 0,
              right: 4,
              child: IconButton(
                key: const ValueKey('owner-profile-close'),
                tooltip: ProfileStrings.close,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Only filled-in values; a section without any is left out entirely.
  static List<Widget> _detailSections(OwnerDetails d) {
    String label(String key) => ProfileStrings.ownerOption(key);
    List<String> labels(List<String> keys) => [for (final k in keys) label(k)];
    final sections = <_InfoSection>[
      _InfoSection(
        key: const ValueKey('owner-info-about'),
        title: ProfileStrings.aboutMeSection,
        children: [
          if (d.ageGroup.isNotEmpty)
            _InfoLine(ProfileStrings.ageGroup, label(d.ageGroup)),
          if (d.occupation.isNotEmpty)
            _InfoLine(ProfileStrings.occupation, d.occupation),
          if (d.interests.isNotEmpty)
            _InfoChips(ProfileStrings.interests, labels(d.interests)),
          if (d.languages.isNotEmpty)
            _InfoChips(ProfileStrings.languages, labels(d.languages)),
        ],
      ),
      _InfoSection(
        key: const ValueKey('owner-info-social'),
        title: ProfileStrings.socialSection,
        children: [
          if (d.lookingFor.isNotEmpty)
            _InfoChips(ProfileStrings.lookingFor, labels(d.lookingFor)),
          if (d.favoriteActivities.isNotEmpty)
            _InfoChips(
              ProfileStrings.favoriteActivities,
              labels(d.favoriteActivities),
            ),
          if (d.walkTimes.isNotEmpty)
            _InfoChips(ProfileStrings.walkTimes, labels(d.walkTimes)),
          if (d.walkPace.isNotEmpty)
            _InfoLine(ProfileStrings.walkPace, label(d.walkPace)),
          if (d.groupWalks) _InfoCheck(ProfileStrings.groupWalks),
        ],
      ),
      _InfoSection(
        key: const ValueKey('owner-info-experience'),
        title: ProfileStrings.experienceSection,
        children: [
          if (d.dogExperience.isNotEmpty)
            _InfoLine(ProfileStrings.dogExperience, label(d.dogExperience)),
          if (d.sharesAdvice) _InfoCheck(ProfileStrings.sharesAdvice),
          if (d.volunteerInterest) _InfoCheck(ProfileStrings.volunteerInterest),
        ],
      ),
      _InfoSection(
        key: const ValueKey('owner-info-extra'),
        title: ProfileStrings.extraSection,
        children: [
          if (d.favoriteBreed.isNotEmpty)
            _InfoLine(ProfileStrings.favoriteBreed, d.favoriteBreed),
          if (d.favoriteWalkSpot.isNotEmpty)
            _InfoLine(ProfileStrings.favoriteWalkSpot, d.favoriteWalkSpot),
          if (d.instagram.isNotEmpty) _InstagramLine(details: d),
        ],
      ),
    ];
    return [
      for (final section in sections)
        if (section.children.isNotEmpty) section,
    ];
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
          for (final child in children) ...[const SizedBox(height: 10), child],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}

class _InfoChips extends StatelessWidget {
  const _InfoChips(this.label, this.values);

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final value in values) PersonalityBadge(label: value)],
        ),
      ],
    );
  }
}

class _InfoCheck extends StatelessWidget {
  const _InfoCheck(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _InstagramLine extends StatelessWidget {
  const _InstagramLine({required this.details});

  final OwnerDetails details;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(details.instagramUrl);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => const ExternalLinkLauncher().open(uri),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '@${details.instagram}',
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('owner-profile-message'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.ink),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(ProfileStrings.retry)),
        ],
      ),
    );
  }
}

/// Owner photo, or the person placeholder (never a dog picture).
class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      key: const ValueKey('owner-photo-placeholder'),
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.45,
          color: AppColors.primaryDeep,
        ),
      ),
    );
    final usable = url.startsWith('http://') || url.startsWith('https://');
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: usable
            ? DogImage(
                url: url,
                seed: url,
                width: size,
                height: size,
                fallback: placeholder,
              )
            : placeholder,
      ),
    );
  }
}

class _DogAvatar extends StatelessWidget {
  const _DogAvatar({required this.url, required this.name, required this.size});

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
