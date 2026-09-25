import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/images/image_upload_service.dart';
import '../../../../core/utils/content_validation_service.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../discover/data/dog_profile_mapper.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../../domain/dog_draft.dart';
import '../../domain/dog_enums.dart';
import '../../domain/dogs_exception.dart';
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
        if (draft.photos.length > 5) {
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
    final picker = ImagePicker();
    final remaining = 5 - state.draft.photos.length;
    if (remaining <= 0 || state.uploadingPhotos) {
      return;
    }
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) {
      return;
    }
    await _uploadPicked(picked);
  }

  Future<void> addFromCamera() async {
    if (state.draft.photos.length >= 5 || state.uploadingPhotos) {
      return;
    }
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) {
      return;
    }
    await _uploadPicked([photo]);
  }

  Future<void> _uploadPicked(List<XFile> files) async {
    state = state.copyWith(
      uploadingPhotos: true,
      submit: const AsyncData<void>(null),
    );
    final urls = [...state.draft.photos];
    var failed = false;
    Object? lastError;
    for (final file in files) {
      if (urls.length >= 5) {
        break;
      }
      try {
        final bytes = await file.readAsBytes();
        debugPrint(
          '[IMAGE UPLOAD] Onboarding file name=${file.name} mime=${file.mimeType} bytes=${bytes.length}',
        );
        urls.add(await ImageUploadService.upload(bytes));
      } catch (error) {
        debugPrint('[IMAGE UPLOAD] Onboarding caller caught: $error');
        failed = true;
        lastError = error;
      }
    }
    state = state.copyWith(
      draft: state.draft.copyWith(photos: urls),
      uploadingPhotos: false,
      submit: failed
          ? AsyncError(
              DogsException(
                lastError?.toString() ?? AppStrings.photoUploadFailed,
              ),
              StackTrace.current,
            )
          : const AsyncData<void>(null),
    );
  }

  void removePhoto(int index) {
    final photos = [...state.draft.photos]..removeAt(index);
    updateDraft(state.draft.copyWith(photos: photos));
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

  Future<bool> submit() async {
    final error = validateCurrentStep();
    if (error != null) {
      state = state.copyWith(submit: AsyncError(DogsException(error), StackTrace.current));
      return false;
    }
    final owner = ref.read(authStateProvider).value;
    if (owner == null) {
      state = state.copyWith(
        submit: AsyncError(
          const DogsException(AppStrings.mustBeSignedIn),
          StackTrace.current,
        ),
      );
      return false;
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
      final existing = ref.read(localOwnerDogsProvider);
      ref.read(localOwnerDogsProvider.notifier).replace([...existing, dog]);
      final ownerName = owner.displayName ?? '';
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
              ownerLocation: owner.locationLabel.isEmpty
                  ? current.ownerLocation
                  : owner.locationLabel,
              dogs: dogs,
              selectedDogId: dog.id,
            ),
          );
      state = state.copyWith(submit: const AsyncData<void>(null));
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(submit: AsyncError(error, stackTrace));
      return false;
    }
  }
}

final dogOnboardingControllerProvider =
    NotifierProvider<DogOnboardingController, DogOnboardingState>(
  DogOnboardingController.new,
);
