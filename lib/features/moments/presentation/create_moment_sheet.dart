import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../events/data/seed_events.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/moment_model.dart';
import 'moments_controller.dart';
import 'moments_strings.dart';

Future<void> showCreateMomentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: const CreateMomentSheet(),
      );
    },
  );
}

class CreateMomentSheet extends ConsumerStatefulWidget {
  const CreateMomentSheet({super.key});

  @override
  ConsumerState<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends ConsumerState<CreateMomentSheet> {
  final _caption = TextEditingController();
  String _location = EventVenues.names.first;
  String? _dogId;
  XFile? _photo;
  var _isLoading = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final dogs = profile.dogs;
    _dogId ??= profile.selectedDogId.isNotEmpty
        ? profile.selectedDogId
        : (dogs.isEmpty ? null : dogs.first.id);
    final parks = [
      for (final name in EventVenues.names)
        if (!EventVenues.isCustom(name)) name,
    ];
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            MomentsStrings.share,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (dogs.isEmpty)
            const Text(MomentsStrings.noDogs)
          else
            DropdownButtonFormField<String>(
              initialValue: _dogId,
              decoration: const InputDecoration(labelText: MomentsStrings.dog),
              items: [
                for (final dog in dogs)
                  DropdownMenuItem(value: dog.id, child: Text(dog.name)),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) => setState(() => _dogId = value),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: parks.contains(_location) ? _location : parks.first,
            decoration: const InputDecoration(
              labelText: MomentsStrings.location,
            ),
            items: [
              for (final name in parks)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: _isLoading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _location = value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            enabled: !_isLoading,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: MomentsStrings.caption,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickPhoto,
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _photo == null ? MomentsStrings.addPhoto : MomentsStrings.photo,
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(MomentsStrings.uploading),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading || dogs.isEmpty ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(MomentsStrings.publish),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _photo = file);
    }
  }

  Future<void> _save() async {
    final profile = ref.read(profileControllerProvider);
    final caption = _caption.text.trim();
    final dogId = _dogId;
    if (dogId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(MomentsStrings.dogRequired)));
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(MomentsStrings.photoRequired)),
      );
      return;
    }
    final dog = profile.dogs.where((item) => item.id == dogId).toList();
    if (dog.isEmpty) {
      return;
    }
    final selected = dog.first;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(momentsControllerProvider.notifier)
          .create(
            draft: MomentModel(
              id: '',
              authorUserId: '',
              authorName: profile.ownerName,
              dogId: selected.id,
              dogName: selected.name,
              dogBreed: selected.breed,
              dogPhotoUrl: selected.photoUrl,
              momentPhotoUrl: '',
              caption: caption,
              locationName: _location,
              likes: const [],
              commentsCount: 0,
              createdAt: DateTime.now(),
            ),
            photo: _photo,
          );

      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(MomentsStrings.successTitle)),
            ],
          ),
          content: const Text(MomentsStrings.successBody),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text(MomentsStrings.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      final details = e.toString().replaceFirst('Exception: ', '').trim();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text(MomentsStrings.errorTitle)),
            ],
          ),
          content: Text(
            MomentsStrings.createErrorBody(
              details.isEmpty ? MomentsStrings.publishError : details,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(MomentsStrings.close),
            ),
          ],
        ),
      );
    }
  }
}
