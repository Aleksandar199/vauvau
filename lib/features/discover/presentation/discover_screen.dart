import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_screen.dart';
import '../domain/discover_profile.dart';
import 'discover_controller.dart';
import 'discover_strings.dart';
import 'widgets/directory_cards.dart';
import 'widgets/discover_empty_state.dart';
import 'widgets/discover_filters_bottom_sheet.dart';
import 'widgets/swipe_dog_card.dart';
import 'widgets/tilt_on_drag.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    final controller = ref.read(discoverControllerProvider.notifier);
    final dogs = state.visible;

    ref.listen(discoverControllerProvider, (previous, next) {
      if (next.query.isEmpty && _search.text.isNotEmpty) {
        _search.clear();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: controller.setQuery,
                      decoration: const InputDecoration(
                        hintText: DiscoverStrings.searchHint,
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: DiscoverStrings.filters,
                    onPressed: () => showDiscoverFiltersSheet(context),
                    icon: const Icon(Icons.tune),
                  ),
                  IconButton.filledTonal(
                    tooltip: state.gridMode
                        ? DiscoverStrings.listView
                        : DiscoverStrings.gridView,
                    onPressed: controller.toggleView,
                    icon: Icon(
                      state.gridMode ? Icons.view_list : Icons.grid_view,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: DiscoverStrings.chipAll,
                      selected: state.category == DiscoverCategory.all,
                      onTap: () =>
                          controller.setCategory(DiscoverCategory.all),
                    ),
                    _CategoryChip(
                      label: DiscoverStrings.chipNearby,
                      selected: state.category == DiscoverCategory.nearby,
                      onTap: () =>
                          controller.setCategory(DiscoverCategory.nearby),
                    ),
                    _CategoryChip(
                      label: DiscoverStrings.chipWalking,
                      selected: state.category == DiscoverCategory.walking,
                      onTap: () =>
                          controller.setCategory(DiscoverCategory.walking),
                    ),
                    _CategoryChip(
                      label: DiscoverStrings.chipSmall,
                      selected: state.category == DiscoverCategory.small,
                      onTap: () =>
                          controller.setCategory(DiscoverCategory.small),
                    ),
                    _CategoryChip(
                      label: DiscoverStrings.chipLarge,
                      selected: state.category == DiscoverCategory.large,
                      onTap: () =>
                          controller.setCategory(DiscoverCategory.large),
                    ),
                    _CategoryChip(
                      label: DiscoverStrings.chipPlayful,
                      selected: state.category == DiscoverCategory.playful,
                      onTap: () =>
                          controller.setCategory(DiscoverCategory.playful),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dogs.isEmpty
              ? const DiscoverEmptyState()
              : state.gridMode
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: dogs.length,
                      itemBuilder: (context, index) {
                        final dog = dogs[index];
                        return TiltOnDrag(
                          onTap: () => _openDetails(dog),
                          child: DiscoverGridCard(
                            profile: dog,
                            onTap: () => _openDetails(dog),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: dogs.length,
                      itemBuilder: (context, index) {
                        final dog = dogs[index];
                        return TiltOnDrag(
                          onTap: () => _openDetails(dog),
                          child: DiscoverListCard(
                            profile: dog,
                            onTap: () => _openDetails(dog),
                            onMessage: () => _openChat(dog),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _openDetails(DiscoverProfile profile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DogDetailSheet(
        profile: profile,
        onPass: () {
          Navigator.of(sheetContext).pop();
          _swipe(profile, 'dislike');
        },
        onLike: () {
          Navigator.of(sheetContext).pop();
          _swipe(profile, 'like');
        },
        onMessage: () {
          Navigator.of(sheetContext).pop();
          _openChat(profile);
        },
      ),
    );
  }

  Future<void> _swipe(DiscoverProfile profile, String action) async {
    final matched = await ref
        .read(discoverControllerProvider.notifier)
        .swipe(profile, action);
    if (!mounted) {
      return;
    }
    final message = matched
        ? DiscoverStrings.newMatch
        : action == 'like'
            ? DiscoverStrings.likedToast
            : DiscoverStrings.passedToast;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    if (matched) {
      _openChat(profile);
    }
  }

  void _openChat(DiscoverProfile profile) {
    final chatId = ref.read(chatInboxProvider.notifier).openFromMatch(profile);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: chatId),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
