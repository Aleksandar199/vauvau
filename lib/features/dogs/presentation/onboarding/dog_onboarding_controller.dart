import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/content_validation_service.dart';
import '../../../../services/storage_service.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../discover/data/dog_profile_mapper.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../../domain/dog.dart';
import '../../domain/dog_draft.dart';
import '../../domain/dog_enums.dart';
import '../../domain/dogs_exception.dart';
import '../widgets/preference_chip_group.dart';
import '../dog_providers.dart';

class DogOnboardingState {
  const DogOnboardingState({
    this.step = 0,
    this.draft = const DogDraft(),
    this.submit = const AsyncData<void>(null),
    this.uploadingPhotos = false,
  });

  final int step;
  final DogDraft draft;
  final AsyncValue<void> submit;
  final bool uploadingPhotos;

  bool get isSubmitting => submit.isLoading;

  DogOnboardingState copyWith({
    int? step,
    DogDraft? draft,
    AsyncValue<void>? submit,
    bool? uploadingPhotos,
  }) {
    return DogOnboardingState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      submit: submit ?? this.submit,
      uploadingPhotos: uploadingPhotos ?? this.uploadingPhotos,
    );
  }
}

class DogOnboardingController extends Notifier<DogOnboardingState> {
  static const int stepCount = 3;

  final _storage = StorageService();

  @override
  DogOnboardingState build() {
    ref.watch(authStateProvider.select((value) => value.value?.uid));
    return const DogOnboardingState();
  }

  void updateDraft(DogDraft draft) {
    state = state.copyWith(draft: draft, submit: const AsyncData<void>(null));
  }

  String? validateCurrentStep() {
    final draft = state.draft;
    switch (state.step) {
      case 0:
        if (draft.name.trim().isEmpty) {
          return AppStrings.dogNameRequired;
        }
        if (draft.breed.trim().isEmpty) {
          return AppStrings.dogBreedRequired;
        }
        if (draft.gender == null) {
          return AppStrings.dogGenderRequired;
        }
        if (draft.ageYears == null || draft.ageYears! < 0 || draft.ageYears! > 30) {
          return AppStrings.dogAgeRequired;
        }
        return ContentValidationService.validateText(draft.name) ??
            ContentValidationService.validateText(draft.breed);
      case 1:
        if (draft.size == null) {
          return AppStrings.dogSizeRequired;
        }
        if (draft.temperament.isEmpty) {
          return AppStrings.dogTemperamentRequired;
        }
        return null;
      case 2:
        if (draft.photos.length > AppStrings.maxDogPhotos) {
          return AppStrings.dogPhotosRequired;
        }
        return null;
      default:
        return null;
    }
  }

  bool nextStep() {
    final error = validateCurrentStep();
    if (error != null) {
      state = state.copyWith(submit: AsyncError(DogsException(error), StackTrace.current));
      return false;
    }
    if (state.step < stepCount - 1) {
      state = state.copyWith(
        step: state.step + 1,
        submit: const AsyncData<void>(null),
      );
    }
    return true;
  }

  void previousStep() {
    if (state.step > 0) {
      state = state.copyWith(
        step: state.step - 1,
        submit: const AsyncData<void>(null),
      );
    }
  }

  Future<void> addPhotos() async {
    final remaining = AppStrings.maxDogPhotos - state.draft.photos.length;
    if (remaining <= 0 || state.uploadingPhotos) {
      return;
    }
    state = state.copyWith(
      uploadingPhotos: true,
      submit: const AsyncData<void>(null),
    );
    try {
      final urls = await _storage.uploadImagesFromGallery(
        folderName: 'pets',
        limit: remaining,
      );
      if (urls.isEmpty) {
        state = state.copyWith(uploadingPhotos: false);
        return;
      }
      final next = [...state.draft.photos, ...urls]
          .take(AppStrings.maxDogPhotos)
          .toList();
      state = state.copyWith(
        draft: state.draft.copyWith(photos: next),
        uploadingPhotos: false,
        submit: const AsyncData<void>(null),
      );
    } catch (error, stack) {
      state = state.copyWith(
        uploadingPhotos: false,
        submit: AsyncError(
          error is DogsException
              ? error
              : DogsException(AppStrings.photoUploadFailed),
          stack,
        ),
      );
    }
  }

  Future<void> addFromCamera() async {
    if (state.draft.photos.length >= AppStrings.maxDogPhotos ||
        state.uploadingPhotos) {
      return;
    }
    state = state.copyWith(
      uploadingPhotos: true,
      submit: const AsyncData<void>(null),
    );
    final url = await _storage.uploadImageFromCamera(folderName: 'pets');
    if (url == null || url.isEmpty) {
      state = state.copyWith(uploadingPhotos: false);
      return;
    }
    if (!(url.startsWith('https://') || url.startsWith('http://'))) {
      state = state.copyWith(
        uploadingPhotos: false,
        submit: AsyncError(
          DogsException(AppStrings.photoUploadFailed),
          StackTrace.current,
        ),
      );
      return;
    }
    state = state.copyWith(
      draft: state.draft.copyWith(photos: [...state.draft.photos, url]),
      uploadingPhotos: false,
      submit: const AsyncData<void>(null),
    );
  }

  void removePhoto(int index) {
    if (index < 0 || index >= state.draft.photos.length) {
      return;
    }
    final photos = [...state.draft.photos];
    final removed = photos.removeAt(index);
    updateDraft(state.draft.copyWith(photos: photos));
    unawaited(_storage.tryDeleteImageByUrl(removed));
  }

  void toggleTemperament(DogTemperament tag) {
    final current = [...state.draft.temperament];
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    updateDraft(state.draft.copyWith(temperament: current));
  }

  void toggleLike(String tag) {
    updateDraft(
      state.draft.copyWith(
        likesTags: togglePreference(state.draft.likesTags, tag),
      ),
    );
  }

  void toggleDislike(String tag) {
    updateDraft(
      state.draft.copyWith(
        dislikesTags: togglePreference(state.draft.dislikesTags, tag),
      ),
    );
  }

  Future<Dog?> submit() async {
    final error = validateCurrentStep();
    if (error != null) {
      state = state.copyWith(submit: AsyncError(DogsException(error), StackTrace.current));
      return null;
    }
    final owner = ref.read(authStateProvider).value;
    if (owner == null) {
      state = state.copyWith(
        submit: AsyncError(
          DogsException(AppStrings.mustBeSignedIn),
          StackTrace.current,
        ),
      );
      return null;
    }
    state = state.copyWith(submit: const AsyncLoading());
    try {
      final seeded = state.draft.copyWith(
        cityId: owner.cityId.isNotEmpty ? owner.cityId : state.draft.cityId,
        neighborhoodId: owner.neighborhoodId.isNotEmpty
            ? owner.neighborhoodId
            : state.draft.neighborhoodId,
      );
      final dog = await ref
          .read(dogsRepositoryProvider)
          .createFirstDog(owner: owner, draft: seeded)
          .timeout(const Duration(seconds: 20));
      state = state.copyWith(submit: const AsyncData<void>(null));
      return dog;
    } catch (error, stackTrace) {
      state = state.copyWith(submit: AsyncError(error, stackTrace));
      return null;
    }
  }

  void applyCreatedDog(Dog dog) {
    final owner = ref.read(authStateProvider).value;
    final existing = ref.read(localOwnerDogsProvider);
    ref.read(localOwnerDogsProvider.notifier).replace([...existing, dog]);
    final ownerName = owner?.displayName ?? '';
    final profileDog = discoverProfileFromDog(dog, ownerName: ownerName);
    final current = ref.read(profileControllerProvider);
    final dogs = [
      for (final item in current.dogs)
        if (item.id != profileDog.id) item,
      profileDog,
    ];
    ref.read(profileControllerProvider.notifier).save(
          current.copyWith(
            ownerName: ownerName.isEmpty ? current.ownerName : ownerName,
            ownerLocation: owner == null || owner.locationLabel.isEmpty
                ? current.ownerLocation
                : owner.locationLabel,
            dogs: dogs,
            selectedDogId: dog.id,
          ),
        );
  }
}

final dogOnboardingControllerProvider =
    NotifierProvider<DogOnboardingController, DogOnboardingState>(
  DogOnboardingController.new,
);
