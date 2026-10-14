import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/services/storage_service.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = StorageService(currentUserId: () => 'uid-42');
  });

  test('nests flat roots under signed-in uid', () {
    expect(storage.ownerFolder('pets'), 'pets/uid-42');
    expect(storage.ownerFolder('moments'), 'moments/uid-42');
    expect(storage.ownerFolder('users'), 'users/uid-42');
    expect(storage.ownerFolder('chats'), 'chats/uid-42');
    expect(storage.ownerFolder(''), 'uploads/uid-42');
  });

  test('keeps already-scoped owner paths', () {
    expect(storage.ownerFolder('pets/uid-42'), 'pets/uid-42');
    expect(
      storage.ownerFolder('moments/uid-42/story'),
      'moments/uid-42/story',
    );
  });

  test('rewrites wrong second segment to auth uid', () {
    expect(storage.ownerFolder('pets/other-user'), 'pets/uid-42/other-user');
  });

  test('explicit ownerId overrides resolver', () {
    expect(
      storage.ownerFolder('pets', ownerId: 'owner-9'),
      'pets/owner-9',
    );
  });

  test('throws when no signed-in user', () {
    final guest = StorageService(currentUserId: () => null);
    expect(() => guest.ownerFolder('pets'), throwsStateError);
  });
}
