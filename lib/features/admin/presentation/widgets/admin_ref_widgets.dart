import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../domain/admin_models.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';

/// Round photo (person or dog), with an icon fallback.
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.url,
    this.size = 32,
    this.icon = Icons.person,
  });

  final String url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: DogImage(
          url: url,
          width: size,
          height: size,
          fallback: ColoredBox(
            color: scheme.primary.withValues(alpha: 0.12),
            child: Icon(icon, size: size * 0.6, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}

/// "Prijavio: [foto] Milica" – name and photo from `users/{uid}` instead of
/// the raw uid. Falls back to „Nepoznat korisnik“.
class AdminUserLabel extends ConsumerWidget {
  const AdminUserLabel({
    super.key,
    required this.uid,
    this.prefix = '',
    this.avatarSize = 24,
    this.style,
    this.onTap,
    this.fallbackName = '',
  });

  final String uid;
  final String prefix;

  /// Shown when the profile is gone (e.g. name stored on the feedback).
  final String fallbackName;
  final double avatarSize;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserRefProvider(uid));
    final user = async.value;
    final name = async.isLoading && user == null
        ? AdminStrings.loadingName
        : (user != null && !user.exists && fallbackName.trim().isNotEmpty)
            ? fallbackName.trim()
            : AdminStrings.userName(user);
    final label = prefix.isEmpty ? name : '$prefix: $name';
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminAvatar(url: user?.photoUrl ?? '', size: avatarSize),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (user != null && user.role != AdminRoles.user) ...[
          const SizedBox(width: 6),
          AdminRoleBadge(role: user.role),
        ],
      ],
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class AdminRoleBadge extends StatelessWidget {
  const AdminRoleBadge({super.key, required this.role, this.suspended = false});

  final String role;
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    final (label, color) = suspended
        ? (AdminStrings.suspendedBadge, const Color(0xFFB91C1C))
        : switch (role) {
            AdminRoles.admin => (
                AdminStrings.adminBadge,
                Theme.of(context).colorScheme.primary,
              ),
            AdminRoles.partner => (
                AdminStrings.partnerBadge,
                const Color(0xFF0E7490),
              ),
            _ => (AdminStrings.userBadge, Colors.grey.shade600),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Preview of the reported content: dog, moment, message or user.
class AdminTargetPreview extends ConsumerWidget {
  const AdminTargetPreview({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.missing = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DogImage(url: imageUrl, width: 52, height: 52),
            )
          else
            Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontStyle: missing ? FontStyle.italic : null,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
