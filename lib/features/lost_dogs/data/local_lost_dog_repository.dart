import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../domain/lost_dog.dart';
import '../domain/lost_dog_repository.dart';

class LocalLostDogRepository implements LostDogRepository {
  LocalLostDogRepository({List<LostDog>? seed})
      : _dogs = List<LostDog>.from(seed ?? const []);

  final List<LostDog> _dogs;
  final _controller = StreamController<List<LostDog>>.broadcast();

  void dispose() => _controller.close();

  @override
  Stream<List<LostDog>> watchLostDogs() async* {
    yield List<LostDog>.from(_dogs);
    yield* _controller.stream;
  }

  @override
  Future<void> reportLostDog(LostDog dog, {XFile? photo}) async {
    final id = dog.id.isEmpty
        ? 'lost-${DateTime.now().millisecondsSinceEpoch}'
        : dog.id;
    _dogs.insert(
      0,
      dog.copyWith(
        id: id,
        imageUrl: dog.imageUrl.isEmpty
            ? 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80'
            : dog.imageUrl,
      ),
    );
    _controller.add(List<LostDog>.from(_dogs));
  }

  @override
  Future<void> markFound(String id) async {
    for (var i = 0; i < _dogs.length; i++) {
      if (_dogs[i].id == id) {
        _dogs[i] = _dogs[i].copyWith(status: LostDogStatus.resolved);
      }
    }
    _controller.add(List<LostDog>.from(_dogs));
  }

  @override
  Future<void> deleteLostDog(String id) async {
    _dogs.removeWhere((dog) => dog.id == id);
    _controller.add(List<LostDog>.from(_dogs));
  }
}
