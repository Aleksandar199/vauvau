import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage_service.dart';
import '../../moments/domain/moment_model.dart';
import '../../moments/presentation/moment_feed_controller.dart';
import '../../moments/presentation/moments_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/story.dart';
import 'stories_strings.dart';
import 'story_providers.dart';

/// Uploads a story image to the author's permanent `moments/{uid}/` folder;
/// the same [fileStem] overwrites instead of adding a copy.
typedef StoryArchiveUploader =
    Future<String> Function(Uint8List bytes, String fileStem);

final storyArchiveUploaderProvider = Provider<StoryArchiveUploader>((ref) {
  return (bytes, fileStem) => StorageService().uploadBytes(
    bytes: bytes,
    folderName: 'moments',
    fileStem: fileStem,
  );
});

/// Saves my 24h story (`stories`) as a permanent highlight-only moment, so
/// it can go into the dog's "Istaknute priče" (highlights reference moment
/// ids). The copy has no `kind`, so it never enters the Moments feed and is
/// not counted as a post. Story media itself expires with the story.
class StoryHighlightArchiver {
  StoryHighlightArchiver(this._ref);

  final Ref _ref;

  static String momentIdFor(Story story) => 'story_${story.id}';

  /// Returns the moment to add to a highlight. Retrying the same story
  /// reuses the same moment id and file (no duplicates).
  Future<MomentModel> archive(Story story) async {
    final profile = _ref.read(profileControllerProvider);
    final dogs = profile.dogs;
    final dog = dogs.where((dog) => dog.id == story.dogId).firstOrNull ??
        dogs.where((dog) => dog.id == profile.selectedDogId).firstOrNull ??
        dogs.firstOrNull;
    if (dog == null) {
      throw StateError(StoriesStrings.highlightNeedsDog);
    }
    final bytes = await _ref.read(storyRepositoryProvider).loadMedia(story);
    final id = momentIdFor(story);
    final url = await _ref.read(storyArchiveUploaderProvider)(bytes, id);
    final draft = MomentModel(
      id: id,
      kind: MomentKind.legacy,
      authorUserId: story.authorUserId,
      authorName: story.authorName,
      authorPhotoUrl: story.authorPhotoUrl,
      dogId: dog.id,
      dogName: dog.name,
      dogBreed: dog.breed,
      dogPhotoUrl: dog.photoUrls.isEmpty ? '' : dog.photoUrls.first,
      momentPhotoUrl: url,
      // A video story stays a video (the uploader keeps its content type).
      mediaType: story.isVideo ? MomentMediaType.video : MomentMediaType.image,
      caption: story.caption.trim(),
      locationName: '',
      likes: const [],
      commentsCount: 0,
      createdAt: story.createdAt,
    );
    await _ref.read(momentsRepositoryProvider).createMoment(draft);
    // The highlight editor picks from my archive.
    _ref.invalidate(myMomentArchiveProvider);
    return draft;
  }
}

final storyHighlightArchiverProvider = Provider<StoryHighlightArchiver>(
  StoryHighlightArchiver.new,
);
