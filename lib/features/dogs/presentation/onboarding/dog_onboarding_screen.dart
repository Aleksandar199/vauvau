import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/auth_controller.dart';
import 'dog_onboarding_controller.dart';
import 'steps/area_step.dart';
import 'steps/basics_step.dart';
import 'steps/personality_step.dart';
import 'steps/photos_step.dart';

class DogOnboardingScreen extends ConsumerWidget {
  const DogOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dogOnboardingControllerProvider);
    final controller = ref.read(dogOnboardingControllerProvider.notifier);
    final error = state.submit.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.onboardingTitle} (${state.step + 1}/${DogOnboardingController.stepCount})',
        ),
        actions: [
          TextButton(
            onPressed: state.isSubmitting
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (state.step + 1) / DogOnboardingController.stepCount,
          ),
          Expanded(child: _step(state, controller)),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (state.step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isSubmitting ? null : controller.previousStep,
                        child: const Text(AppStrings.back),
                      ),
                    ),
                  if (state.step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: state.isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                            label: state.step == DogOnboardingController.stepCount - 1
                                ? AppStrings.createDogProfile
                                : AppStrings.next,
                            onPressed: () async {
                              if (state.step ==
                                  DogOnboardingController.stepCount - 1) {
                                await controller.submit();
                              } else {
                                controller.nextStep();
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(DogOnboardingState state, DogOnboardingController controller) {
    switch (state.step) {
      case 0:
        return BasicsStep(
          draft: state.draft,
          onChanged: controller.updateDraft,
        );
      case 1:
        return PersonalityStep(
          draft: state.draft,
          onChanged: controller.updateDraft,
          onToggleTemperament: controller.toggleTemperament,
        );
      case 2:
        return AreaStep(
          draft: state.draft,
          onChanged: controller.updateDraft,
        );
      default:
        return PhotosStep(
          photos: state.draft.photos,
          onAddGallery: controller.addPhotos,
          onAddCamera: controller.addFromCamera,
          onRemove: controller.removePhoto,
        );
    }
  }
}
