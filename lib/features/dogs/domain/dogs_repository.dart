import '../../auth/domain/app_user.dart';
import 'dog.dart';
import 'dog_draft.dart';

abstract class DogsRepository {
  Stream<List<Dog>> watchByOwner(String ownerId);

  Future<Dog> createFirstDog({
    required AppUser owner,
    required DogDraft draft,
  });
}
