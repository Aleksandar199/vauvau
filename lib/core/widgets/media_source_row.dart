import 'package:flutter/material.dart';

import '../media/video_strings.dart';
import '../theme/app_colors.dart';

/// Photo / video switch + "Galerija" and "Kamera" as two equal tiles in one
/// row ("Nova priča", "Nova objava"). Tiles are InkWells, not theme buttons,
/// so the theme's full-width `minimumSize` never squeezes them.
class MediaSourceRow extends StatelessWidget {
  const MediaSourceRow({
    super.key,
    required this.video,
    required this.onVideoChanged,
    required this.onGallery,
    required this.onCamera,
    this.enabled = true,
    this.showCamera = true,
    this.dark = false,
    this.keyPrefix = 'media',
    this.hint,
  });

  final bool video;
  final ValueChanged<bool> onVideoChanged;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final bool enabled;
  final bool showCamera;

  /// White text on a dark background (story preview).
  final bool dark;

  /// Keys: `{prefix}-mode-photo`, `{prefix}-mode-video`, `{prefix}-gallery`,
  /// `{prefix}-camera`.
  final String keyPrefix;

  /// Small line under the tiles (e.g. video limits).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = dark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _ModeChip(
              key: ValueKey('$keyPrefix-mode-photo'),
              label: VideoStrings.photo,
              icon: Icons.photo_outlined,
              selected: !video,
              dark: dark,
              onTap: enabled ? () => onVideoChanged(false) : null,
            ),
            _ModeChip(
              key: ValueKey('$keyPrefix-mode-video'),
              label: VideoStrings.video,
              icon: Icons.videocam_outlined,
              selected: video,
              dark: dark,
              onTap: enabled ? () => onVideoChanged(true) : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SourceTile(
                key: ValueKey('$keyPrefix-gallery'),
                icon: video
                    ? Icons.video_library_outlined
                    : Icons.photo_library_outlined,
                label: VideoStrings.gallery,
                dark: dark,
                onTap: enabled ? onGallery : null,
              ),
            ),
            if (showCamera) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _SourceTile(
                  key: ValueKey('$keyPrefix-camera'),
                  icon: video
                      ? Icons.videocam_outlined
                      : Icons.photo_camera_outlined,
                  label: video ? VideoStrings.recordVideo : VideoStrings.camera,
                  dark: dark,
                  onTap: enabled ? onCamera : null,
                ),
              ),
            ],
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: hintColor),
          ),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final idle = dark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final background = selected
        ? AppColors.primary
        : (dark ? const Color(0x33FFFFFF) : Colors.transparent);
    final foreground = selected ? Colors.white : idle;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : idle.withValues(alpha: 0.35),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final background = dark ? const Color(0x26FFFFFF) : AppColors.primarySoft;
    final foreground = dark ? Colors.white : AppColors.primaryDeep;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
