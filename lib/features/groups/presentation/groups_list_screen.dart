import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/utils/content_validation_service.dart';
import '../domain/group_ranking.dart';
import '../domain/groups_models.dart';
import 'group_chat_screen.dart';
import 'groups_controller.dart';
import 'groups_strings.dart';
import 'widgets/group_card.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

/// Groups page: "Za šetnju" (global + local groups, city and type filters) and
/// "Po rasama" (canonical breed registry, search, city filter).
class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  String? _cityId;
  GroupCategory? _category;
  final _breedSearch = TextEditingController();
  var _showAllBreeds = false;

  @override
  void dispose() {
    _breedSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(GroupsStrings.title),
          actions: [
            IconButton(
              tooltip: GroupsStrings.createGroup,
              onPressed: () => showCreateGroupSheet(context, cityId: _cityId),
              icon: const Icon(Icons.group_add_outlined),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: GroupsStrings.tabWalks),
              Tab(text: GroupsStrings.tabBreeds),
            ],
          ),
        ),
        body: TabBarView(children: [_walksTab(context), _breedsTab(context)]),
      ),
    );
  }

  // --- shared -------------------------------------------------------------

  Widget _cityChips() {
    return _ChipRow(
      label: GroupsStrings.cityLabel,
      chips: [
        _ChipData(
          GroupsStrings.allSerbia,
          _cityId == null,
          () => setState(() => _cityId = null),
        ),
        for (final city in SerbiaLocations.cities)
          _ChipData(
            city.name,
            _cityId == city.id,
            () => setState(() => _cityId = city.id),
          ),
      ],
    );
  }

  Widget _errorMessage() {
    return _Message(
      icon: Icons.cloud_off_outlined,
      text: GroupsStrings.loadError,
      actionLabel: GroupsStrings.retry,
      onAction: () => ref.invalidate(groupsControllerProvider),
    );
  }

  static const Widget _loading = Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator()),
  );

  Future<void> _refresh() async {
    ref.invalidate(groupsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  // --- Za šetnju -----------------------------------------------------------

  Widget _walksTab(BuildContext context) {
    final groups = ref.watch(groupsControllerProvider);
    final status = ref.watch(groupsLoadStateProvider);
    final memberId = ref.watch(groupsMemberIdProvider);
    final filtered = GroupRanking.walkGroups(
      groups,
      GroupFilter(cityId: _cityId, category: _category),
    );
    final cityName = SerbiaLocations.cityById(_cityId ?? '')?.name;

    final header = <Widget>[
      Text(
        GroupsStrings.subtitle,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 12),
      _cityChips(),
      const SizedBox(height: 8),
      _ChipRow(
        label: GroupsStrings.typeLabel,
        chips: [
          _ChipData(
            GroupsStrings.allTypes,
            _category == null,
            () => setState(() => _category = null),
          ),
          for (final category in GroupCategory.values)
            _ChipData(
              GroupsStrings.category(category),
              _category == category,
              () => setState(() => _category = category),
            ),
        ],
      ),
      const SizedBox(height: 12),
    ];

    Widget body;
    if (status.error != null) {
      body = _errorMessage();
    } else if (!status.loaded && groups.isEmpty) {
      body = _loading;
    } else if (filtered.isEmpty) {
      final noLocal = cityName != null && _category == null;
      body = _Message(
        icon: Icons.pets_outlined,
        title: GroupsStrings.noGroupsTitle,
        text: noLocal
            ? GroupsStrings.noGroupsInCity(cityName)
            : GroupsStrings.noGroupsFilter,
        actionLabel: GroupsStrings.startGroup,
        onAction: () =>
            showCreateGroupSheet(context, cityId: _cityId, category: _category),
      );
    } else {
      body = Column(
        children: [
          for (final group in filtered) ...[
            GroupCard(
              group: group,
              isMember: group.isMember(memberId),
              onJoin: () => _join(context, group),
              onOpenChat: () => _openChat(context, group),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [...header, body],
      ),
    );
  }

  // --- Po rasama -----------------------------------------------------------

  Widget _breedsTab(BuildContext context) {
    final groups = ref.watch(groupsControllerProvider);
    final status = ref.watch(groupsLoadStateProvider);
    final memberId = ref.watch(groupsMemberIdProvider);
    final query = _breedSearch.text.trim();
    final searching = query.isNotEmpty;
    final breeds = searching
        ? GroupRanking.searchBreeds(query)
        : _showAllBreeds
        ? GroupRanking.searchBreeds('')
        : GroupRanking.featuredBreeds;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          TextField(
            controller: _breedSearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: GroupsStrings.searchBreeds,
              suffixIcon: searching
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_breedSearch.clear),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          _cityChips(),
          const SizedBox(height: 12),
          if (!searching && !_showAllBreeds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                GroupsStrings.featuredBreeds,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          if (status.error != null)
            _errorMessage()
          else if (!status.loaded && groups.isEmpty)
            _loading
          else if (breeds.isEmpty)
            _Message(icon: Icons.search_off, text: GroupsStrings.noBreeds)
          else
            for (final breed in breeds) ...[
              _BreedTile(
                breed: breed,
                group: GroupRanking.groupForBreed(
                  groups,
                  breed,
                  cityId: _cityId,
                ),
                memberId: memberId,
                onJoin: (group) => _join(context, group),
                onOpen: (group) => _openChat(context, group),
                onSuggest: () => showCreateGroupSheet(
                  context,
                  cityId: _cityId,
                  breedKey: breed,
                ),
              ),
              const SizedBox(height: 10),
            ],
          if (!searching)
            Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _showAllBreeds = !_showAllBreeds),
                child: Text(
                  _showAllBreeds
                      ? GroupsStrings.showFeaturedBreeds
                      : GroupsStrings.showAllBreeds,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, BreedGroup group) async {
    await ref.read(groupsControllerProvider.notifier).join(group.id);
    if (!context.mounted) {
      return;
    }
    await _openChat(context, group);
  }

  Future<void> _openChat(BuildContext context, BreedGroup group) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupChatScreen(groupId: group.id),
      ),
    );
  }
}

Future<void> showCreateGroupSheet(
  BuildContext context, {
  String? cityId,
  GroupCategory? category,
  String? breedKey,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CreateGroupSheet(
      initialCityId: cityId,
      initialCategory: category,
      breedKey: breedKey,
    ),
  );
}

class _ChipData {
  const _ChipData(this.label, this.selected, this.onTap);

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.chips});

  final String label;
  final List<_ChipData> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Semantics(
            label: '$label: ${chip.label}',
            selected: chip.selected,
            child: ChoiceChip(
              label: Text(chip.label),
              selected: chip.selected,
              onSelected: (_) => chip.onTap(),
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 44, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          Text(text, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _BreedTile extends StatelessWidget {
  const _BreedTile({
    required this.breed,
    required this.group,
    required this.memberId,
    required this.onJoin,
    required this.onOpen,
    required this.onSuggest,
  });

  final String breed;
  final BreedGroup? group;
  final String memberId;
  final void Function(BreedGroup group) onJoin;
  final void Function(BreedGroup group) onOpen;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final found = group;
    final cityName = found == null
        ? ''
        : SerbiaLocations.cityById(found.cityId)?.name ?? '';
    final subtitle = found == null
        ? GroupsStrings.noBreedGroup
        : cityName.isEmpty
        ? GroupsStrings.globalGroup
        : '${GroupsStrings.localGroup} · $cityName';
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.pets, color: theme.colorScheme.primary),
        title: Text(
          GroupRanking.breedLabel(breed),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: found == null
            ? OutlinedButton(
                onPressed: onSuggest,
                child: Text(GroupsStrings.suggestGroup),
              )
            : found.isMember(memberId)
            ? OutlinedButton(
                onPressed: () => onOpen(found),
                child: Text(GroupsStrings.openChat),
              )
            : FilledButton(
                onPressed: () => onJoin(found),
                child: Text(GroupsStrings.join),
              ),
      ),
    );
  }
}

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({
    super.key,
    this.initialCityId,
    this.initialCategory,
    this.breedKey,
  });

  final String? initialCityId;
  final GroupCategory? initialCategory;

  /// Canonical breed name when suggesting a breed group.
  final String? breedKey;

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.breedKey == null
        ? ''
        : GroupRanking.breedLabel(widget.breedKey!),
  );
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  late String? _cityId = SerbiaLocations.cityById(
    widget.initialCityId ?? '',
  )?.id;
  late GroupCategory _category =
      widget.initialCategory ?? GroupCategory.general;
  var _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                GroupsStrings.createGroupTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: GroupsStrings.groupName),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return GroupsStrings.nameRequired;
                  }
                  return ContentValidationService.validateTitle(value!);
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: GroupsStrings.groupDescription,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 10),
              if (widget.breedKey == null)
                DropdownButtonFormField<GroupCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: GroupsStrings.categoryLabel,
                  ),
                  items: [
                    for (final c in GroupCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Text(GroupsStrings.category(c)),
                      ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(
                          () => _category = value ?? GroupCategory.general,
                        ),
                ),
              if (widget.breedKey == null) const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: _cityId,
                decoration: InputDecoration(
                  labelText: GroupsStrings.cityOptional,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(GroupsStrings.allSerbia),
                  ),
                  for (final city in SerbiaLocations.cities)
                    DropdownMenuItem<String?>(
                      value: city.id,
                      child: Text(city.name),
                    ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _cityId = value),
              ),
              if (widget.breedKey == null && _cityId != null) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  enabled: !_isLoading,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: GroupsStrings.locationOptional,
                  ),
                ),
              ],
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(GroupsStrings.submitGroup),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(groupsControllerProvider.notifier)
          .createGroup(
            title: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            cityId: _cityId ?? '',
            category: _category,
            locationName: _locationController.text.trim(),
            breedKey: widget.breedKey ?? '',
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
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(GroupsStrings.requestSentTitle)),
            ],
          ),
          content: Text(GroupsStrings.requestSentBody),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(GroupsStrings.ok),
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
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text(GroupsStrings.createErrorTitle)),
            ],
          ),
          content: Text(
            GroupsStrings.createErrorBody(
              details.isEmpty ? GroupsStrings.createFailed : details,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(GroupsStrings.close),
            ),
          ],
        ),
      );
    }
  }
}
