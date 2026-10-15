import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/events/data/firestore_events_repository.dart';
import 'package:vauvau/features/groups/data/firestore_groups_repository.dart';

void main() {
  test('first like on a group message without likes field works', () async {
    final firestore = FakeFirebaseFirestore();
    final message = firestore
        .collection('breed_groups')
        .doc('g1')
        .collection('messages')
        .doc('m1');
    await message.set({'senderId': 'other', 'text': 'Zdravo'});
    final repo = FirestoreGroupsRepository(
      firestore: firestore,
      currentUserId: 'me',
      senderName: 'Ja',
      senderAvatarUrl: '',
    );

    await repo.toggleMessageLike(groupId: 'g1', messageId: 'm1');
    expect((await message.get()).data()!['likes'], ['me']);

    await repo.toggleMessageLike(groupId: 'g1', messageId: 'm1');
    expect((await message.get()).data()!['likes'], isEmpty);
  });

  test('first like on an event message without likes field works', () async {
    final firestore = FakeFirebaseFirestore();
    final message = firestore
        .collection('events')
        .doc('e1')
        .collection('messages')
        .doc('m1');
    await message.set({'senderId': 'other', 'text': 'Zdravo'});
    final repo = FirestoreEventsRepository(
      firestore: firestore,
      currentUserId: 'me',
      senderName: 'Ja',
      senderAvatarUrl: '',
    );

    await repo.toggleMessageLike(eventId: 'e1', messageId: 'm1');
    expect((await message.get()).data()!['likes'], ['me']);
  });
}
