import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../domain/lost_dog.dart';
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
    final catalog = ref.watch(lostDogsControllerProvider);
    final lost = ref.watch(activeLostDogsProvider);
    final found = ref.watch(activeFoundDogsProvider);
    final uid = ref.watch(lostDogReporterIdProvider);
    final theme = Theme.of(context);
    final visible = switch (_tab) {
      _LostDogsTab.lost => lost,
      _LostDogsTab.found => found,
      _LostDogsTab.all => [...lost, ...found],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(LostDogStrings.title),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              text: '${LostDogStrings.tabLost} ${lost.length}',
            ),
            Tab(
              text: '${LostDogStrings.tabFound} ${found.length}',
            ),
            const Tab(text: LostDogStrings.tabAll),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reportCase,
        backgroundColor: const Color(0xFFB91C1C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(LostDogStrings.addCta),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                ? Center(child: Text(_emptyLabel))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final dog = visible[index];
                      return _LostDogCard(
                        dog: dog,
                        isOwner: uid.isNotEmpty && uid == dog.uploaderUserId,
                        matches: dog.isFoundListing
                            ? LostDogMatcher.matchesFor(dog, catalog)
                            : const [],
                      );
                    },
                  ),
          ),
        ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == LostDogType.found
              ? LostDogStrings.publishedFound
              : LostDogStrings.published,
        ),
      ),
    );
    if (type == LostDogType.found) {
      _tabs.animateTo(1);
    }
  }
}

class _LostDogCard extends ConsumerWidget {
  const _LostDogCard({
    required this.dog,
    required this.isOwner,
    required this.matches,
  });

  final LostDog dog;
  final bool isOwner;
  final List<LostDog> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final found = dog.isFoundListing;
    final accent = found ? const Color(0xFF43A047) : Colors.redAccent;
    final match = matches.isEmpty ? null : matches.first;
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent, width: 1.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildDogImage(dog.imageUrl, seed: dog.id),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: found
                          ? const Color(0xCC2E7D32)
                          : const Color(0xCCB91C1C),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      found
                          ? LostDogStrings.foundBadge
                          : LostDogStrings.missingBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                Text(
                  found
                      ? LostDogStrings.foundHeadline(dog.dogName)
                      : LostDogStrings.missingHeadline(dog.dogName),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(LostDogStrings.breedLine(dog.breed)),
                Text(LostDogStrings.place(dog.city, dog.neighborhood)),
                Text(
                  found
                      ? LostDogStrings.foundOn(
                          LostDogStrings.formatDate(dog.eventDate),
                        )
                      : LostDogStrings.lostOn(
                          LostDogStrings.formatDate(dog.eventDate),
                        ),
                ),
                if (dog.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(dog.description),
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
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => showLostDogSightingSheet(
                    context: context,
                    ref: ref,
                    dog: dog,
                  ),
                  child: Text(
                    found
                        ? LostDogStrings.contactFinder
                        : LostDogStrings.sighting,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _confirmResolved(context, ref, dog),
                    child: Text(
                      found
                          ? LostDogStrings.markResolved
                          : LostDogStrings.found,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmDelete(context, ref, dog.id),
                    child: const Text(LostDogStrings.deletePost),
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
          title: const Text(LostDogStrings.foundConfirmTitle),
          content: const Text(LostDogStrings.foundConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(LostDogStrings.cancel),
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
          title: const Text(LostDogStrings.deleteConfirmTitle),
          content: const Text(LostDogStrings.deleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(LostDogStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(LostDogStrings.deletePost),
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
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.4),
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
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onOpen,
            child: Text(LostDogStrings.viewMatchProfile(match.dogName)),
          ),
        ],
      ),
    );
  }
}
