import '../../../core/images/dog_photo_urls.dart';
import '../../events/data/seed_events.dart';
import '../domain/moment_model.dart';

abstract final class SeedMoments {
  static final List<MomentModel> all = [
    MomentModel(
      id: 'moment-liman',
      authorUserId: 'seed-nikola',
      authorName: 'Nikola',
      dogId: 'bobi',
      dogName: 'Bobi',
      dogBreed: 'Zlatni retriver',
      dogPhotoUrl:
          'https://images.unsplash.com/photo-1633722715463-d30f4f325e24?auto=format&fit=crop&w=800&q=80',
      momentPhotoUrl: kFallbackDogPhotoUrl,
      caption: 'Danas smo upoznali 3 nova druga u parku! 🐾',
      locationName: EventVenues.names.first,
      likes: const ['seed-1', 'seed-2', 'seed-3'],
      commentsCount: 1,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    MomentModel(
      id: 'moment-kamenicki',
      authorUserId: 'seed-jelena',
      authorName: 'Jelena',
      dogId: 'lola',
      dogName: 'Lola',
      dogBreed: 'Labrador',
      dogPhotoUrl:
          'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=800&q=80',
      momentPhotoUrl:
          'https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?auto=format&fit=crop&w=800&q=80',
      caption: 'Jutarnja kafa i mirna šetnja. Preporuka! ☕',
      locationName: 'Kamenički park',
      likes: const ['seed-4'],
      commentsCount: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MomentModel(
      id: 'moment-tvrdjava',
      authorUserId: 'seed-stefan',
      authorName: 'Stefan',
      dogId: 'kiki',
      dogName: 'Kiki',
      dogBreed: 'Haski',
      dogPhotoUrl:
          'https://images.unsplash.com/photo-1605568427561-40dd23c2acea?auto=format&fit=crop&w=800&q=80',
      momentPhotoUrl:
          'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80',
      caption: 'Pogled sa Tvrđave i puno trčanja. 🌅',
      locationName: 'Petrovaradinska tvrđava',
      likes: const ['seed-5', 'seed-6'],
      commentsCount: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
  ];
}
