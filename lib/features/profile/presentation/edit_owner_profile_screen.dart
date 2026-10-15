import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/serbia_locations.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../../core/widgets/city_neighborhood_fields.dart';
import '../../../services/storage_service.dart';
import '../../auth/domain/owner_details.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../dogs/presentation/widgets/preference_chip_group.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

class EditOwnerProfileScreen extends ConsumerStatefulWidget {
  const EditOwnerProfileScreen({super.key});

  @override
  ConsumerState<EditOwnerProfileScreen> createState() =>
      _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState
    extends ConsumerState<EditOwnerProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _customNeighborhood;
  late final TextEditingController _occupation;
  late final TextEditingController _favoriteBreed;
  late final TextEditingController _favoriteWalkSpot;
  late final TextEditingController _instagram;
  late String _cityId;
  late String? _neighborhoodId;
  late OwnerDetails _details;
  String? _instagramError;
  var _uploading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _name = TextEditingController(text: profile.ownerName);
    _bio = TextEditingController(text: profile.ownerBio);
    _details = profile.ownerDetails;
    _occupation = TextEditingController(text: _details.occupation);
    _favoriteBreed = TextEditingController(text: _details.favoriteBreed);
    _favoriteWalkSpot = TextEditingController(text: _details.favoriteWalkSpot);
    _instagram = TextEditingController(
      text: _details.instagram.isEmpty ? '' : '@${_details.instagram}',
    );
    _cityId = profile.ownerCityId.isEmpty
        ? SerbiaLocations.cities.first.id
        : profile.ownerCityId;
    final storedHood = profile.ownerNeighborhoodId;
    if (storedHood.isEmpty) {
      _neighborhoodId = null;
      _customNeighborhood = TextEditingController();
    } else if (SerbiaLocations.usesCustomNeighborhood(_cityId, storedHood)) {
      _neighborhoodId = SerbiaLocations.customNeighborhoodId;
      _customNeighborhood = TextEditingController(
        text: profile.ownerNeighborhoodName.isNotEmpty
            ? profile.ownerNeighborhoodName
            : _fallbackCustomName(profile.ownerLocation),
      );
    } else {
      _neighborhoodId = storedHood;
      _customNeighborhood = TextEditingController();
    }
  }

  String _fallbackCustomName(String location) {
    final parts = location.split(',');
    if (parts.length < 2) {
      return '';
    }
    return parts.sublist(1).join(',').trim();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _customNeighborhood.dispose();
    _occupation.dispose();
    _favoriteBreed.dispose();
    _favoriteWalkSpot.dispose();
    _instagram.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_uploading) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final storage = StorageService();
      final previous =
          ref.read(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
      final url = await storage.uploadImageFromGallery(folderName: 'users');
      if (url == null) {
        return;
      }
      if (!url.startsWith('http')) {
        throw StateError(AppStrings.photoUploadFailed);
      }
      await ref
          .read(profileControllerProvider.notifier)
          .saveOwnerCustomPhoto(url);
      await storage.tryDeleteImageByUrl(previous);
    } catch (error) {
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: AppStrings.photoUploadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _save() {
    final invalid =
        ContentValidationService.validateText(_name.text) ??
        ContentValidationService.validateText(_bio.text, allowEmpty: true) ??
        ContentValidationService.validateText(
          _occupation.text,
          allowEmpty: true,
        ) ??
        ContentValidationService.validateText(
          _favoriteBreed.text,
          allowEmpty: true,
        ) ??
        ContentValidationService.validateText(
          _favoriteWalkSpot.text,
          allowEmpty: true,
        );
    if (invalid != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(invalid)));
      return;
    }
    final instagram = OwnerDetails.normalizeInstagram(_instagram.text);
    if (instagram == null) {
      setState(() => _instagramError = ProfileStrings.instagramInvalid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfileStrings.instagramInvalid)),
      );
      return;
    }
    final city = SerbiaLocations.cityById(_cityId);
    if (city == null || _neighborhoodId == null || _neighborhoodId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.neighborhoodRequired)),
      );
      return;
    }
    final customName = _customNeighborhood.text.trim();
    if (SerbiaLocations.usesCustomNeighborhood(_cityId, _neighborhoodId) &&
        customName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.customNeighborhoodRequired)),
      );
      return;
    }
    final neighborhood = SerbiaLocations.resolveNeighborhoodName(
      cityId: _cityId,
      neighborhoodId: _neighborhoodId,
      customName: customName,
    );
    final storedHoodId = SerbiaLocations.usesCustomNeighborhood(
          _cityId,
          _neighborhoodId,
        )
        ? SerbiaLocations.customNeighborhoodId
        : _neighborhoodId!;
    final current = ref.read(profileControllerProvider);
    ref
        .read(profileControllerProvider.notifier)
        .save(
          current.copyWith(
            ownerName: _name.text.trim(),
            ownerBio: _bio.text.trim(),
            ownerLocation: SerbiaLocations.formatPlace(
              city.name,
              neighborhood,
            ),
            ownerCityId: _cityId,
            ownerNeighborhoodId: storedHoodId,
            ownerNeighborhoodName: neighborhood,
            ownerDetails: _details.copyWith(
              occupation: _occupation.text.trim(),
              favoriteBreed: _favoriteBreed.text.trim(),
              favoriteWalkSpot: _favoriteWalkSpot.text.trim(),
              instagram: instagram,
            ),
            dogs: [
              for (final dog in current.dogs)
                dog.copyWith(
                  location: SerbiaLocations.formatPlace(
                    city.name,
                    neighborhood,
                  ),
                ),
            ],
          ),
          writeOwnerDetails: true,
        );
    Navigator.of(context).pop(true);
  }

  /// Reads the list from the current [_details] (not from the last build),
  /// so quick consecutive taps never lose a selection.
  void _toggle(
    List<String> Function(OwnerDetails d) read,
    String key,
    OwnerDetails Function(List<String> next) apply,
  ) {
    setState(() => _details = apply(togglePreference(read(_details), key)));
  }

  Widget _multiChoice({
    required String title,
    required List<String> options,
    required List<String> Function(OwnerDetails d) read,
    required OwnerDetails Function(List<String> next) apply,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PreferenceChipGroup(
        title: title,
        options: options,
        selected: read(_details),
        labelOf: ProfileStrings.ownerOption,
        onToggle: (key) => _toggle(read, key, apply),
        selectedColor: scheme.primaryContainer,
        selectedForeground: scheme.onPrimaryContainer,
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    required String label,
    required int maxLength,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _switch(String title, bool value, OwnerDetails Function(bool) apply) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (next) => setState(() => _details = apply(next)),
    );
  }

  List<Widget> _detailSections() {
    final d = _details;
    return [
      Text(
        ProfileStrings.optionalSectionsHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      const SizedBox(height: 8),
      _DetailsSection(
        key: const ValueKey('owner-section-about'),
        icon: Icons.person_outline_rounded,
        title: ProfileStrings.aboutMeSection,
        children: [
          _SingleChoiceChips(
            title: ProfileStrings.ageGroup,
            options: OwnerDetailOptions.ageGroups,
            selected: d.ageGroup,
            onChanged: (key) =>
                setState(() => _details = _details.copyWith(ageGroup: key)),
          ),
          _textField(
            _occupation,
            label: ProfileStrings.occupation,
            hint: ProfileStrings.occupationHint,
            maxLength: OwnerDetails.occupationMaxLength,
          ),
          _multiChoice(
            title: ProfileStrings.interests,
            options: OwnerDetailOptions.interests,
            read: (d) => d.interests,
            apply: (next) => _details.copyWith(interests: next),
          ),
          _multiChoice(
            title: ProfileStrings.languages,
            options: OwnerDetailOptions.languages,
            read: (d) => d.languages,
            apply: (next) => _details.copyWith(languages: next),
          ),
        ],
      ),
      _DetailsSection(
        key: const ValueKey('owner-section-social'),
        icon: Icons.directions_walk_rounded,
        title: ProfileStrings.socialSection,
        children: [
          _multiChoice(
            title: ProfileStrings.lookingFor,
            options: OwnerDetailOptions.lookingFor,
            read: (d) => d.lookingFor,
            apply: (next) => _details.copyWith(lookingFor: next),
          ),
          _multiChoice(
            title: ProfileStrings.favoriteActivities,
            options: OwnerDetailOptions.activities,
            read: (d) => d.favoriteActivities,
            apply: (next) => _details.copyWith(favoriteActivities: next),
          ),
          _multiChoice(
            title: ProfileStrings.walkTimes,
            options: OwnerDetailOptions.walkTimes,
            read: (d) => d.walkTimes,
            apply: (next) => _details.copyWith(walkTimes: next),
          ),
          _SingleChoiceChips(
            title: ProfileStrings.walkPace,
            options: OwnerDetailOptions.walkPaces,
            selected: d.walkPace,
            onChanged: (key) =>
                setState(() => _details = _details.copyWith(walkPace: key)),
          ),
          _switch(
            ProfileStrings.groupWalks,
            d.groupWalks,
            (value) => _details.copyWith(groupWalks: value),
          ),
        ],
      ),
      _DetailsSection(
        key: const ValueKey('owner-section-experience'),
        icon: Icons.pets_outlined,
        title: ProfileStrings.experienceSection,
        children: [
          _SingleChoiceChips(
            title: ProfileStrings.dogExperience,
            options: OwnerDetailOptions.experienceLevels,
            selected: d.dogExperience,
            onChanged: (key) => setState(
              () => _details = _details.copyWith(dogExperience: key),
            ),
          ),
          _switch(
            ProfileStrings.sharesAdvice,
            d.sharesAdvice,
            (value) => _details.copyWith(sharesAdvice: value),
          ),
          _switch(
            ProfileStrings.volunteerInterest,
            d.volunteerInterest,
            (value) => _details.copyWith(volunteerInterest: value),
          ),
        ],
      ),
      _DetailsSection(
        key: const ValueKey('owner-section-extra'),
        icon: Icons.star_outline_rounded,
        title: ProfileStrings.extraSection,
        children: [
          _textField(
            _favoriteBreed,
            label: ProfileStrings.favoriteBreed,
            hint: ProfileStrings.breedHint,
            maxLength: OwnerDetails.favoriteBreedMaxLength,
          ),
          _textField(
            _favoriteWalkSpot,
            label: ProfileStrings.favoriteWalkSpot,
            hint: ProfileStrings.favoriteWalkSpotHint,
            maxLength: OwnerDetails.favoriteWalkSpotMaxLength,
          ),
          TextField(
            key: const ValueKey('owner-instagram-field'),
            controller: _instagram,
            keyboardType: TextInputType.url,
            autocorrect: false,
            maxLength: 80,
            onChanged: (_) {
              if (_instagramError != null) {
                setState(() => _instagramError = null);
              }
            },
            decoration: InputDecoration(
              labelText: ProfileStrings.instagram,
              hintText: ProfileStrings.instagramHint,
              prefixIcon: const Icon(Icons.camera_alt_outlined),
              errorText: _instagramError,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final email = profile.ownerEmail;
    final avatarUrl =
        ref.watch(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
    final hasPhoto =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');

    return Scaffold(
      appBar: AppBar(title: Text(ProfileStrings.editProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      backgroundImage: hasPhoto
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: _uploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : (hasPhoto
                                ? null
                                : const Icon(Icons.person, size: 36)),
                    ),
                    IconButton.filledTonal(
                      onPressed: _uploading ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(AppStrings.ownerPhotoLabel),
              ],
            ),
          ),
          SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: ProfileStrings.ownerName,
              border: OutlineInputBorder(),
            ),
          ),
          if (email.isNotEmpty) ...[
            SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                labelText: AppStrings.emailLabel,
                border: OutlineInputBorder(),
              ),
              child: Text(email),
            ),
          ],
          const SizedBox(height: 16),
          CityNeighborhoodFields(
            cityId: _cityId,
            neighborhoodId: _neighborhoodId,
            customNeighborhoodController: _customNeighborhood,
            onCityChanged: (value) {
              setState(() {
                _cityId = value;
                _neighborhoodId = null;
                _customNeighborhood.clear();
              });
            },
            onNeighborhoodChanged: (value) {
              setState(() {
                _neighborhoodId = value;
                if (!SerbiaLocations.isCustomNeighborhoodId(value)) {
                  _customNeighborhood.clear();
                }
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: ProfileStrings.ownerBio,
              hintText: ProfileStrings.ownerBioHint,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ..._detailSections(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            onPressed: _save,
            child: Text(ProfileStrings.saveChanges),
          ),
        ),
      ),
    );
  }
}

/// Collapsible card for one group of optional profile fields.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Icon(icon, color: AppColors.primaryDeep, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// One-of-many chips; tapping the selected chip again clears the value.
class _SingleChoiceChips extends StatelessWidget {
  const _SingleChoiceChips({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in options)
                ChoiceChip(
                  label: Text(ProfileStrings.ownerOption(key)),
                  selected: selected == key,
                  onSelected: (_) => onChanged(selected == key ? '' : key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
