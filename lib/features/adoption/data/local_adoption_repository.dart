import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../domain/adoption_dog.dart';
import '../domain/adoption_repository.dart';
import 'mock_adoption_dogs.dart';

class LocalAdoptionRepository implements AdoptionRepository {
  LocalAdoptionRepository({List<AdoptionDog>? seed})
      : _dogs = List<AdoptionDog>.from(seed ?? mockAdoptionDogs);

  final List<AdoptionDog> _dogs;
  final _controller = StreamController<List<AdoptionDog>>.broadcast();

  void dispose() => _controller.close();

  @override
  Stream<List<AdoptionDog>> watchAdoptionDogs() async* {
    yield List<AdoptionDog>.from(_dogs);
    yield* _controller.stream;
  }

  @override
  Future<List<AdoptionDog>> getAdoptionDogs() async {
    return List<AdoptionDog>.from(_dogs);
  }

  @override
  Future<void> addAdoptionDog(
    AdoptionDog dog, {
    List<XFile> photos = const [],
    String city = '',
    String neighborhood = '',
  }) async {
    final urls = List<String>.from(dog.imageUrls);
    if (urls.isEmpty) {
      urls.add(
        'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80',
      );
    }
    final id = dog.id.isEmpty
        ? 'adopt-${DateTime.now().millisecondsSinceEpoch}'
        : dog.id;
    _dogs.insert(
      0,
      dog.copyWith(id: id, imageUrls: urls, createdAt: DateTime.now()),
    );
    _controller.add(List<AdoptionDog>.from(_dogs));
  }

  @override
  Future<void> markAdopted(String id) async {
    for (var i = 0; i < _dogs.length; i++) {
      if (_dogs[i].id == id) {
        _dogs[i] = _dogs[i].copyWith(status: 'adopted');
      }
    }
    _controller.add(List<AdoptionDog>.from(_dogs));
  }
}
