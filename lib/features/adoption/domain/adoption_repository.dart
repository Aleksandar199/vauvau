import 'package:image_picker/image_picker.dart';

import 'adoption_dog.dart';

abstract class AdoptionRepository {
  Stream<List<AdoptionDog>> watchAdoptionDogs();

  Future<List<AdoptionDog>> getAdoptionDogs();

  Future<void> addAdoptionDog(
    AdoptionDog dog, {
    List<XFile> photos = const [],
    String city = '',
    String neighborhood = '',
  });

  Future<void> markAdopted(String id);
}
