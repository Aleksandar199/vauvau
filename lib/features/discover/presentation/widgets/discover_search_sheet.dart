import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../discover_controller.dart';
import '../discover_strings.dart';

Future<void> showDiscoverSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return const _DiscoverSearchSheet();
    },
  );
}

class _DiscoverSearchSheet extends ConsumerStatefulWidget {
  const _DiscoverSearchSheet();

  @override
  ConsumerState<_DiscoverSearchSheet> createState() =>
      _DiscoverSearchSheetState();
}

class _DiscoverSearchSheetState extends ConsumerState<_DiscoverSearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(discoverControllerProvider).query,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DiscoverStrings.search,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: ref.read(discoverControllerProvider.notifier).setQuery,
            onSubmitted: (_) => Navigator.of(context).pop(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: DiscoverStrings.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: DiscoverStrings.reset,
                      onPressed: () {
                        _controller.clear();
                        ref.read(discoverControllerProvider.notifier).setQuery('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
