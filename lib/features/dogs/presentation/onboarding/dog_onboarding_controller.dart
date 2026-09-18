import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/serbia_locations.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/dog_draft.dart';
import '../../domain/dog_enums.dart';
import '../../domain/dogs_exception.dart';
import '../dog_providers.dart';

class DogOnboardingState {
  const DogOnboardingState({
    this.step = 0,
    this.draft = const DogDraft(),
    this.submit = const AsyncData<void>(null),
  });

  final int step;
  final DogDraft draft;
  final AsyncValue<void> submit;

  bool get isSubmitting => submit.isLoading;

  DogOnboardingState copyWith({
    int? step,
    DogDraft? draft,
    AsyncValue<void>? submit,
  }) {
    return DogOnboardingState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      submit: submit ?? this.submit,
    );
  }
}

class DogOnboardingController extends Notifier<DogOnboardingState> {
  static const int stepCount = 4;

  @override
  DogOnboardingState build() => const DogOnboardingState();

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
        return null;
      case 1:
        if (draft.size == null) {
          return AppStrings.dogSizeRequired;
        }
        if (draft.energyLevel == null) {
          return AppStrings.dogEnergyRequired;
        }
        if (draft.temperament.isEmpty) {
          return AppStrings.dogTemperamentRequired;
        }
        return null;
      case 2:
        if (draft.cityId == null || draft.neighborhoodId == null) {
          return AppStrings.dogAreaRequired;
        }
        if (SerbiaLocations.cityById(draft.cityId!) == null) {
          return AppStrings.dogAreaRequired;
        }
        return null;
      case 3:
        if (draft.photos.isEmpty || draft.photos.length > 5) {
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
    if (remaining <= 0) {
      return;
    }
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) {
      return;
    }
    final next = [...state.draft.photos, ...picked].take(5).toList();
    updateDraft(state.draft.copyWith(photos: next));
  }

  Future<void> addFromCamera() async {
    if (state.draft.photos.length >= 5) {
      return;
    }
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) {
      return;
    }
    updateDraft(state.draft.copyWith(photos: [...state.draft.photos, photo]));
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
          const DogsException('You must be signed in.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    state = state.copyWith(submit: const AsyncLoading());
    try {
      await ref.read(dogsRepositoryProvider).createFirstDog(
            owner: owner,
            draft: state.draft,
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
