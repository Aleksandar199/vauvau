import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/constants/serbia_locations.dart';
import '../../domain/groups_models.dart';
import '../groups_strings.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.isMember,
    required this.onJoin,
    required this.onOpenChat,
  });

  final BreedGroup group;
  final bool isMember;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityName = SerbiaLocations.cityById(group.cityId)?.name ?? '';
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 72,
                height: 72,
                child: buildDogImage(group.imageUrl, seed: group.id),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    group.verifiedMemberCount > 0
                        ? GroupsStrings.memberCount(group.verifiedMemberCount)
                        : GroupsStrings.noMembersYet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (cityName.isNotEmpty) _Tag(label: cityName),
                      if (group.hasLocation)
                        _Tag(label: group.locationName, icon: Icons.place),
                      if (group.scope != GroupScope.breed &&
                          group.category != GroupCategory.general)
                        _Tag(label: GroupsStrings.category(group.category)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(group.description, style: theme.textTheme.bodyMedium),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: isMember
                        ? OutlinedButton(
                            onPressed: onOpenChat,
                            child: Text(GroupsStrings.openChat),
                          )
                        : FilledButton(
                            onPressed: onJoin,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(GroupsStrings.join),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: scheme.onSurface),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
