import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_cards.dart';
import '../../../core/widgets/feed_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/constants/serbia_locations.dart';
import '../domain/lost_dog.dart';
import '../domain/lost_dog_city.dart';
import '../domain/lost_dog_matcher.dart';
import 'lost_dog_actions.dart';
import 'lost_dog_strings.dart';
import 'lost_dogs_controller.dart';
import 'report_lost_dog_sheet.dart';

enum _LostDogsTab { lost, found, all }

class LostDogsScreen extends ConsumerStatefulWidget {
  const LostDogsScreen({super.key});

  @override
  ConsumerState<LostDogsScreen> createState() => _LostDogsScreenState();
}

class _LostDogsScreenState extends ConsumerState<LostDogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  _LostDogsTab get _tab => _LostDogsTab.values[_tabs.index];

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(lostDogsControllerProvider);
    final cityFilter = ref.watch(lostDogCityFilterProvider);
    final cityCatalog = ref.watch(cityLostDogsProvider);
    final lost = ref.watch(cityMissingDogsProvider);
    final found = ref.watch(cityFoundDogsProvider);
    final uid = ref.watch(lostDogReporterIdProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final visible = switch (_tab) {
      _LostDogsTab.lost => lost,
      _LostDogsTab.found => found,
      _LostDogsTab.all => [...lost, ...found],
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(LostDogStrings.title),
        actions: [
          IconButton(
            tooltip: LostDogStrings.addCta,
            onPressed: _reportCase,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: '${LostDogStrings.tabLost} ${lost.length}'),
            Tab(text: '${LostDogStrings.tabFound} ${found.length}'),
            Tab(text: LostDogStrings.tabAll),
          ],
        ),
      ),
      body: catalogAsync.when(
        loading: () => FeedStateView.loadingBody(),
        error: (error, stack) => FeedStateView(
          icon: Icons.error_outline,
          title: LostDogStrings.loadError,
          onRetry: () => ref.read(lostDogsControllerProvider.notifier).reload(),
          retryLabel: LostDogStrings.retry,
        ),
        data: (catalog) {
          // Matches look across every loaded listing, also other cities' old
          // ones (the matcher itself requires the same city).
          final matchCatalog = {
            for (final dog in [...catalog, ...cityCatalog]) dog.id: dog,
          }.values.toList();
          return Column(
            children: [
              _CityFilterBar(
                selected: cityFilter,
                onSelected: (filter) =>
                    ref.read(lostDogCityFilterProvider.notifier).select(filter),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _tab == _LostDogsTab.found
                      ? const Color(0xFF14532D)
                      : const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _tab == _LostDogsTab.found
                      ? LostDogStrings.foundBanner
                      : LostDogStrings.banner,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? FeedStateView(
                        icon: Icons.search_off,
                        title: cityFilter == LostDogCity.all
                            ? _emptyLabel
                            : LostDogStrings.emptyInCity(
                                _cityLabel(cityFilter),
                              ),
                        subtitle: cityFilter == LostDogCity.all
                            ? LostDogStrings.emptySubtitle
                            : LostDogStrings.emptyInCitySubtitle,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final dog = visible[index];
                          return _LostDogCard(
                            dog: dog,
                            isOwner:
                                uid.isNotEmpty && uid == dog.uploaderUserId,
                            isAdmin: isAdmin,
                            matches: dog.isFoundListing
                                ? LostDogMatcher.matchesFor(dog, matchCatalog)
                                : const [],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String get _emptyLabel {
    return switch (_tab) {
      _LostDogsTab.lost => LostDogStrings.empty,
      _LostDogsTab.found => LostDogStrings.emptyFound,
      _LostDogsTab.all => LostDogStrings.emptyAll,
    };
  }

  Future<void> _reportCase() async {
    final type = await showReportCaseChooser(context);
    if (type == null || !mounted) {
      return;
    }
    final saved = await showReportLostDogSheet(context, type: type);
    if (saved != true || !mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(LostDogStrings.publishSuccessTitle)),
            ],
          ),
          content: Text(
            type == LostDogType.found
                ? LostDogStrings.publishedFound
                : LostDogStrings.published,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(LostDogStrings.ok),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (type == LostDogType.found) {
      _tabs.animateTo(1);
    }
  }
}

String _cityLabel(String filter) {
  if (filter == LostDogCity.all) {
    return LostDogStrings.allCities;
  }
  if (filter == LostDogCity.other) {
    return LostDogStrings.otherCity;
  }
  return SerbiaLocations.cityById(filter)?.name ?? filter;
}

/// City chips: Svi gradovi · each [SerbiaLocations] city · Ostalo.
class _CityFilterBar extends StatelessWidget {
  const _CityFilterBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = [
      LostDogCity.all,
      for (final city in SerbiaLocations.cities) city.id,
      LostDogCity.other,
    ];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        key: const ValueKey('lost-dog-city-filter'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return ChoiceChip(
            key: ValueKey('lost-dog-city-$filter'),
            label: Text(_cityLabel(filter)),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _LostDogCard extends ConsumerWidget {
  const _LostDogCard({
    required this.dog,
    required this.isOwner,
    required this.isAdmin,
    required this.matches,
  });

  final LostDog dog;
  final bool isOwner;
  final bool isAdmin;
  final List<LostDog> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final found = dog.isFoundListing;
    final accent = found ? const Color(0xFF15803D) : Colors.red.shade700;
    final match = matches.isEmpty ? null : matches.first;
    final canResolve = isOwner || isAdmin;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: AppCardTokens.borderRadius,
        boxShadow: AppCardTokens.softShadow(0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: AppCardTokens.imageBorderRadius,
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: buildDogImage(dog.imageUrl, seed: dog.id),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      if (!found) ...[
                        StatusBadge(
                          label: LostDogStrings.urgentBadge,
                          tone: StatusBadgeTone.urgent,
                        ),
                        SizedBox(width: 6),
                        StatusBadge(
                          label: LostDogStrings.missingBadge,
                          tone: StatusBadgeTone.warning,
                        ),
                      ] else
                        StatusBadge(
                          label: LostDogStrings.foundBadge,
                          tone: StatusBadgeTone.success,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FallbackIllustrationCaption(url: dog.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitleText(
                  text: found
                      ? LostDogStrings.foundHeadline(dog.dogName)
                      : LostDogStrings.missingHeadline(dog.dogName),
                ),
                SizedBox(height: 6),
                Text(
                  LostDogStrings.breedLine(dog.breed),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                SizedBox(height: 4),
                CardLocationRow(
                  label: LostDogStrings.place(dog.city, dog.neighborhood),
                  iconColor: accent,
                ),
                SizedBox(height: 4),
                CardTimeLabel(
                  label: found
                      ? LostDogStrings.foundOn(
                          LostDogStrings.formatDate(dog.eventDate),
                        )
                      : LostDogStrings.lostOn(
                          LostDogStrings.formatDate(dog.eventDate),
                        ),
                ),
                CardTimeLabel(label: LostDogStrings.timeAgo(dog.createdAt)),
                if (dog.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    dog.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
                if (match != null) ...[
                  const SizedBox(height: 12),
                  _MatchBanner(
                    match: match,
                    onOpen: () => showLostDogProfileSheet(
                      context: context,
                      ref: ref,
                      dog: match,
                    ),
                  ),
                ],
                SizedBox(height: 12),
                DetailPrimaryButton(
                  label: found
                      ? LostDogStrings.contactFinder
                      : LostDogStrings.sighting,
                  icon: found ? Icons.phone : Icons.visibility,
                  onPressed: () => showLostDogSightingSheet(
                    context: context,
                    ref: ref,
                    dog: dog,
                  ),
                ),
                SizedBox(height: 8),
                DetailPrimaryButton(
                  label: LostDogStrings.leaveComment,
                  icon: Icons.chat_bubble_outline,
                  filled: false,
                  onPressed: () => showLostDogCommentsSheet(
                    context: context,
                    ref: ref,
                    dog: dog,
                  ),
                ),
                if (canResolve) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _confirmResolved(context, ref, dog),
                    child: Text(
                      found
                          ? LostDogStrings.markResolved
                          : LostDogStrings.found,
                    ),
                  ),
                ],
                if (isAdmin) ...[
                  TextButton(
                    onPressed: () => _confirmDelete(context, ref, dog.id),
                    child: Text(LostDogStrings.deletePost),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResolved(
    BuildContext context,
    WidgetRef ref,
    LostDog dog,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(LostDogStrings.foundConfirmTitle),
          content: Text(LostDogStrings.foundConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(LostDogStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                dog.isFoundListing
                    ? LostDogStrings.markResolved
                    : LostDogStrings.found,
              ),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await ref.read(lostDogsControllerProvider.notifier).markFound(dog.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(LostDogStrings.deleteConfirmTitle),
          content: Text(LostDogStrings.deleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(LostDogStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(LostDogStrings.deletePost),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await ref.read(lostDogsControllerProvider.notifier).deleteLostDog(id);
    }
  }
}

class _MatchBanner extends StatelessWidget {
  const _MatchBanner({required this.match, required this.onOpen});

  final LostDog match;
  final VoidCallback onOpen;

  static const _ink = Color(0xFF78350F);
  static const _border = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final breed = match.breed.trim().isEmpty
        ? LostDogStrings.breedUnknown
        : match.breed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LostDogStrings.matchBanner(
              LostDogMatchCopy(
                name: match.dogName,
                breed: breed,
                neighborhood: match.neighborhood,
              ),
            ),
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _border),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            icon: const Icon(Icons.search, size: 18, color: _ink),
            label: Text(LostDogStrings.viewMatchProfile(match.dogName)),
          ),
        ],
      ),
    );
  }
}
