import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/moment_model.dart';
import '../domain/story_highlight.dart';
import 'moments_strings.dart';
import 'pointer_safe.dart';
import 'stories_controller.dart';

const Color _danger = Color(0xFFB91C1C);

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Route<void> _instantPage(WidgetBuilder builder) {
  return PageRouteBuilder<void>(
    opaque: true,
    allowSnapshotting: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => builder(context),
  );
}

/// Lets the owner put [moment] into an existing highlight or start a new one.
Future<void> showAddToHighlightSheet(BuildContext context, MomentModel moment) {
  return afterPointerSettles(() async {
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).push<void>(
      _instantPage(
        (_) => _AddToHighlightPage(moment: moment, hostContext: context),
      ),
    );
  });
}

Future<void> showHighlightEditor(
  BuildContext context, {
  required String dogId,
  StoryHighlight? existing,
  String? preselectedMomentId,
}) {
  return afterPointerSettles(() async {
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).push<void>(
      _instantPage(
        (_) => _HighlightEditorPage(
          dogId: dogId,
          existing: existing,
          preselectedMomentId: preselectedMomentId,
        ),
      ),
    );
  });
}

Future<void> showArrangeHighlightsSheet(BuildContext context, String dogId) {
  return afterPointerSettles(() async {
    if (!context.mounted) {
      return;
    }
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push<void>(_instantPage((_) => _ArrangeHighlightsPage(dogId: dogId)));
  });
}

Future<bool> confirmDeleteHighlight(
  BuildContext context,
  WidgetRef ref,
  StoryHighlight highlight,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(MomentsStrings.highlightDelete),
      content: Text(MomentsStrings.highlightDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(MomentsStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _danger),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(MomentsStrings.delete),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return false;
  }
  await ref.read(highlightActionsProvider).delete(highlight);
  return true;
}

class HighlightThumb extends StatelessWidget {
  const HighlightThumb({
    super.key,
    required this.url,
    required this.seed,
    this.size = 48,
  });

  final String url;
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightOutline, width: 1.5),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? const ColoredBox(
                color: AppColors.primarySoft,
                child: Icon(Icons.auto_stories_outlined, size: 20),
              )
            : DogImage(url: url, seed: seed),
      ),
    );
  }
}

class _AddToHighlightPage extends StatelessWidget {
  const _AddToHighlightPage({required this.moment, required this.hostContext});

  final MomentModel moment;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(MomentsStrings.addToHighlight)),
      body: _AddToHighlightSheet(
        moment: moment,
        onCreateNew: () {
          Navigator.of(context).pop();
          afterPointerSettlesIfMounted(hostContext, () {
            showHighlightEditor(
              hostContext,
              dogId: moment.dogId,
              preselectedMomentId: moment.id,
            );
          });
        },
      ),
    );
  }
}

class _AddToHighlightSheet extends ConsumerWidget {
  const _AddToHighlightSheet({required this.moment, required this.onCreateNew});

  final MomentModel moment;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights =
        ref.watch(dogHighlightsProvider(moment.dogId)).asData?.value ??
        const <StoryHighlight>[];
    final all = ref.watch(highlightMomentsProvider(moment.dogId));

    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.add, color: AppColors.primaryDeep),
          ),
          title: Text(MomentsStrings.newHighlightTitle),
          onTap: onCreateNew,
        ),
        for (final highlight in highlights)
          _HighlightToggleTile(
            highlight: highlight,
            coverUrl: highlightCoverUrl(highlight, all),
            selected: highlight.momentIds.contains(moment.id),
            onTap: () => _toggle(context, ref, highlight),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    StoryHighlight highlight,
  ) async {
    final actions = ref.read(highlightActionsProvider);
    final removing = highlight.momentIds.contains(moment.id);
    try {
      if (removing && highlight.momentIds.length == 1) {
        await actions.delete(highlight);
      } else {
        await actions.toggleMoment(highlight, moment.id);
      }
      if (context.mounted) {
        _toast(
          context,
          removing
              ? MomentsStrings.removedFromHighlight
              : MomentsStrings.addedToHighlight,
        );
      }
    } catch (error, stack) {
      debugPrint('Add to highlight failed: $error');
      debugPrint('$stack');
      if (context.mounted) {
        _toast(context, MomentsStrings.loadError);
      }
    }
  }
}

class _HighlightToggleTile extends StatelessWidget {
  const _HighlightToggleTile({
    required this.highlight,
    required this.coverUrl,
    required this.selected,
    required this.onTap,
  });

  final StoryHighlight highlight;
  final String coverUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HighlightThumb(url: coverUrl, seed: highlight.id),
      title: Text(highlight.title),
      subtitle: Text(MomentsStrings.storyCount(highlight.momentIds.length)),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.lightOutline,
      ),
      onTap: onTap,
    );
  }
}

class _HighlightEditorPage extends StatelessWidget {
  const _HighlightEditorPage({
    required this.dogId,
    this.existing,
    this.preselectedMomentId,
  });

  final String dogId;
  final StoryHighlight? existing;
  final String? preselectedMomentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _HighlightEditor(
          dogId: dogId,
          existing: existing,
          preselectedMomentId: preselectedMomentId,
        ),
      ),
    );
  }
}

class _ArrangeHighlightsPage extends StatelessWidget {
  const _ArrangeHighlightsPage({required this.dogId});

  final String dogId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(MomentsStrings.arrangeTitle)),
      body: _ArrangeHighlightsSheet(dogId: dogId),
    );
  }
}

class _HighlightEditor extends ConsumerStatefulWidget {
  const _HighlightEditor({
    required this.dogId,
    this.existing,
    this.preselectedMomentId,
  });

  final String dogId;
  final StoryHighlight? existing;
  final String? preselectedMomentId;

  @override
  ConsumerState<_HighlightEditor> createState() => _HighlightEditorState();
}

class _HighlightEditorState extends ConsumerState<_HighlightEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final Set<String> _selected = {
    ...?widget.existing?.momentIds,
    ?widget.preselectedMomentId,
  };
  late String _cover = widget.existing?.coverMomentId ?? '';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      _error = null;
      if (!_selected.remove(id)) {
        _selected.add(id);
      }
      if (!_selected.contains(_cover)) {
        _cover = '';
      }
    });
  }

  Future<void> _save(List<MomentModel> archive) async {
    final title = _title.text.trim();
    final chosen = [
      for (final moment in archive.reversed)
        if (_selected.contains(moment.id)) moment.id,
    ];
    if (title.isEmpty) {
      setState(() => _error = MomentsStrings.highlightNameRequired);
      return;
    }
    if (chosen.isEmpty) {
      setState(() => _error = MomentsStrings.highlightPickRequired);
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(highlightActionsProvider);
    final cover = chosen.contains(_cover) ? _cover : chosen.last;
    try {
      final existing = widget.existing;
      if (existing == null) {
        final count =
            ref
                .read(dogHighlightsProvider(widget.dogId))
                .asData
                ?.value
                .length ??
            0;
        await actions.create(
          dogId: widget.dogId,
          title: title,
          momentIds: chosen,
          coverMomentId: cover,
          order: count,
        );
      } else {
        await actions.update(
          existing.copyWith(
            title: title,
            momentIds: chosen,
            coverMomentId: cover,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      _toast(context, MomentsStrings.highlightSaved);
      Navigator.of(context).pop();
    } catch (error, stack) {
      debugPrint('Highlight save failed: $error');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = MomentsStrings.loadError;
        });
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    final deleted = await confirmDeleteHighlight(context, ref, existing);
    if (deleted && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final archive = ref.watch(storyArchiveProvider(widget.dogId));
    final theme = Theme.of(context);
    final selectedMoments = [
      for (final moment in archive.reversed)
        if (_selected.contains(moment.id)) moment,
    ];
    final coverId = _selected.contains(_cover)
        ? _cover
        : (selectedMoments.isEmpty ? '' : selectedMoments.last.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: MomentsStrings.cancel,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  widget.existing == null
                      ? MomentsStrings.newHighlightTitle
                      : MomentsStrings.editHighlightTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _saving ? null : () => _save(archive),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(MomentsStrings.highlightSave),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            controller: _title,
            maxLength: StoryHighlight.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: MomentsStrings.highlightName,
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
        ),
        if (selectedMoments.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              MomentsStrings.highlightCover,
              style: theme.textTheme.titleSmall,
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: selectedMoments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final moment = selectedMoments[i];
                final active = moment.id == coverId;
                return GestureDetector(
                  onTap: () => setState(() => _cover = moment.id),
                  child: Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.lightOutline,
                        width: active ? 3 : 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: DogImage(
                        url: moment.momentPhotoUrl,
                        seed: moment.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  MomentsStrings.highlightPickStories,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                MomentsStrings.storyCount(
                  _selected
                      .where((id) => archive.any((m) => m.id == id))
                      .length,
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: archive.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      MomentsStrings.highlightArchiveEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 9 / 16,
                  ),
                  itemCount: archive.length,
                  itemBuilder: (context, i) {
                    final moment = archive[i];
                    return _ArchiveTile(
                      moment: moment,
                      selected: _selected.contains(moment.id),
                      onTap: () => _toggle(moment.id),
                    );
                  },
                ),
        ),
        if (widget.existing != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: _danger),
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(MomentsStrings.highlightDelete),
            ),
          ),
      ],
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.moment,
    required this.selected,
    required this.onTap,
  });

  final MomentModel moment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DogImage(url: moment.momentPhotoUrl, seed: moment.id),
            if (selected) const ColoredBox(color: Color(0x55000000)),
            Positioned(
              left: 6,
              bottom: 6,
              child: Text(
                '${moment.createdAt.day}.${moment.createdAt.month}.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : Colors.white,
                size: 22,
                shadows: const [Shadow(blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrangeHighlightsSheet extends ConsumerStatefulWidget {
  const _ArrangeHighlightsSheet({required this.dogId});

  final String dogId;

  @override
  ConsumerState<_ArrangeHighlightsSheet> createState() =>
      _ArrangeHighlightsSheetState();
}

class _ArrangeHighlightsSheetState
    extends ConsumerState<_ArrangeHighlightsSheet> {
  List<StoryHighlight>? _order;

  @override
  Widget build(BuildContext context) {
    final live =
        ref.watch(dogHighlightsProvider(widget.dogId)).asData?.value ??
        const <StoryHighlight>[];
    final items = _order ?? live;
    final all = ref.watch(highlightMomentsProvider(widget.dogId));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            MomentsStrings.arrangeTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            MomentsStrings.arrangeHint,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: items.length,
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              final next = [...items];
              next.insert(newIndex, next.removeAt(oldIndex));
              setState(() => _order = next);
              ref.read(highlightActionsProvider).reorder(next);
            },
            itemBuilder: (context, i) {
              final highlight = items[i];
              return ListTile(
                key: ValueKey(highlight.id),
                leading: HighlightThumb(
                  url: highlightCoverUrl(highlight, all),
                  seed: highlight.id,
                ),
                title: Text(highlight.title),
                subtitle: Text(
                  MomentsStrings.storyCount(highlight.momentIds.length),
                ),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
