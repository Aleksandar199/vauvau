import 'package:image_picker/image_picker.dart';

import 'lost_dog.dart';

abstract class LostDogRepository {
  /// Newest listings from every city.
  Stream<List<LostDog>> watchLostDogs();

  /// Listings stored with this `cityId` (old listings without it are only
  /// in [watchLostDogs]).
  Stream<List<LostDog>> watchLostDogsInCity(String cityId);

  Stream<List<LostDogComment>> watchComments(String dogId);

  Future<void> reportLostDog(LostDog dog, {XFile? photo});

  Future<void> addComment(String dogId, String text, {String authorName = ''});

  Future<void> toggleCommentLike(String dogId, String commentId);

  Future<void> markFound(String id);

  Future<void> deleteLostDog(String id);
}
