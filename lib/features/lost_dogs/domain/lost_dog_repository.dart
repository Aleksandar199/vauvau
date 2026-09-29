import 'package:image_picker/image_picker.dart';

import 'lost_dog.dart';

abstract class LostDogRepository {
  Stream<List<LostDog>> watchLostDogs();

  Future<void> reportLostDog(LostDog dog, {XFile? photo});

  Future<void> markFound(String id);

  Future<void> deleteLostDog(String id);
}
