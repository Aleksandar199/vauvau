import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../data/firestore_highlights_repository.dart';
import '../data/local_highlights_repository.dart';
import '../domain/highlights_repository.dart';
import '../domain/moment_model.dart';
import '../domain/story_highlight.dart';
import 'moments_controller.dart';

/// Stories of one dog shown back to back in the viewer, oldest first.
class StoryGroup {
  const StoryGroup({
    required this.dogId,
    required this.dogName,
    required this.dogPhotoUrl,
    required this.authorUserId,
    required this.moments,
    this.title,
  });

  factory StoryGroup.fromMoments(List<MomentModel> moments, {String? title}) {
    final first = moments.first;
    return StoryGroup(
      dogId: first.dogId,
      dogName: first.dogName,
      dogPhotoUrl: first.dogPhotoUrl,
      authorUserId: first.authorUserId,
      moments: moments,
      title: title,
    );
  }

  final String dogId;
  final String dogName;
  final String dogPhotoUrl;
  final String authorUserId;
  final List<MomentModel> moments;

  /// Set when the group is a highlight instead of live stories.
  final String? title;

  DateTime get latest => moments.last.createdAt;

  String get coverUrl => moments.last.momentPhotoUrl;
}

final activeStoryGroupsProvider = Provider<List<StoryGroup>>((ref) {
  final moments = ref.watch(visibleMomentsProvider).asData?.value ?? const [];
  final me = ref.watch(momentsMemberIdProvider);
  final now = DateTime.now();
  final byDog = <String, List<MomentModel>>{};
  for (final moment in moments) {
    if (moment.isActiveStory(now)) {
      final key = moment.dogId.isEmpty ? moment.authorUserId : moment.dogId;
      byDog.putIfAbsent(key, () => []).add(moment);
    }
  }
  final groups = [
    for (final items in byDog.values)
      StoryGroup.fromMoments(
        items..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      ),
  ];
  groups.sort((a, b) {
    final aMine = me.isNotEmpty && a.authorUserId == me;
    final bMine = me.isNotEmpty && b.authorUserId == me;
    if (aMine != bMine) {
      return aMine ? -1 : 1;
    }
    return b.latest.compareTo(a.latest);
  });
  return groups;
});

StoryGroup? activeStoryForDog(List<StoryGroup> groups, String dogId) {
  for (final group in groups) {
    if (group.dogId == dogId) {
      return group;
    }
  }
  return null;
}

class SeenStories extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void markSeen(String momentId) {
    if (!state.contains(momentId)) {
      state = {...state, momentId};
    }
  }
}

final seenStoriesProvider = NotifierProvider<SeenStories, Set<String>>(
  SeenStories.new,
);

bool hasUnseen(StoryGroup group, Set<String> seen) =>
    group.moments.any((moment) => !seen.contains(moment.id));

/// Every story the current user posted for [dogId], newest first, including
/// expired ones. Used to pick stories for highlights.
final storyArchiveProvider = Provider.family<List<MomentModel>, String>((
  ref,
  dogId,
) {
  final moments =
      ref.watch(momentsControllerProvider).asData?.value ?? const [];
  final me = ref.watch(momentsMemberIdProvider);
  return [
    for (final moment in moments)
      if (moment.dogId == dogId && me.isNotEmpty && moment.authorUserId == me)
        moment,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final highlightsRepositoryProvider = Provider<HighlightsRepository>((ref) {
  final uid = ref.watch(momentsMemberIdProvider);
  if (isFirebaseReady) {
    return FirestoreHighlightsRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: uid,
    );
  }
  final repo = LocalHighlightsRepository(currentUserId: uid);
  ref.onDispose(repo.dispose);
  return repo;
});

final dogHighlightsProvider =
    StreamProvider.family<List<StoryHighlight>, String>((ref, dogId) {
      return ref.watch(highlightsRepositoryProvider).watchForDog(dogId);
    });

/// Resolves a highlight into a playable group. Stories deleted by the owner
/// are skipped; returns null when nothing is left.
StoryGroup? resolveHighlight(
  StoryHighlight highlight,
  List<MomentModel> allMoments,
) {
  final byId = {for (final moment in allMoments) moment.id: moment};
  final items = [
    for (final id in highlight.momentIds)
      if (byId[id] != null) byId[id]!,
  ];
  if (items.isEmpty) {
    return null;
  }
  return StoryGroup.fromMoments(items, title: highlight.title);
}

String highlightCoverUrl(
  StoryHighlight highlight,
  List<MomentModel> allMoments,
) {
  final byId = {for (final moment in allMoments) moment.id: moment};
  final cover = byId[highlight.coverMomentId];
  if (cover != null) {
    return cover.momentPhotoUrl;
  }
  for (final id in highlight.momentIds) {
    final moment = byId[id];
    if (moment != null) {
      return moment.momentPhotoUrl;
    }
  }
  return '';
}

class HighlightActions {
  HighlightActions(this._ref);

  final Ref _ref;

  HighlightsRepository get _repo => _ref.read(highlightsRepositoryProvider);

  Future<String> create({
    required String dogId,
    required String title,
    required List<String> momentIds,
    String coverMomentId = '',
    int order = 0,
  }) {
    return _repo.create(
      StoryHighlight(
        id: '',
        ownerId: _ref.read(momentsMemberIdProvider),
        dogId: dogId,
        title: title,
        momentIds: momentIds,
        coverMomentId: coverMomentId,
        order: order,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> update(StoryHighlight highlight) => _repo.update(highlight);

  Future<void> delete(StoryHighlight highlight) => _repo.delete(highlight);

  Future<void> reorder(List<StoryHighlight> ordered) => _repo.reorder(ordered);

  Future<void> toggleMoment(StoryHighlight highlight, String momentId) {
    final ids = [...highlight.momentIds];
    if (ids.contains(momentId)) {
      ids.remove(momentId);
    } else {
      ids.add(momentId);
    }
    return _repo.update(highlight.copyWith(momentIds: ids));
  }
}

final highlightActionsProvider = Provider<HighlightActions>(
  HighlightActions.new,
);
