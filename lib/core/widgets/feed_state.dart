import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft grey block used while network images / feed lists load.
class SoftPlaceholder extends StatelessWidget {
  const SoftPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(color: base),
      ),
    );
  }
}

/// Shared empty / loading / error layout for main feed screens.
class FeedStateView extends StatelessWidget {
  const FeedStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel = 'Pokušaj ponovo',
    this.padding = const EdgeInsets.fromLTRB(32, 24, 32, 88),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String retryLabel;
  final EdgeInsetsGeometry padding;

  factory FeedStateView.loading({Key? key}) {
    return FeedStateView(
      key: key,
      icon: Icons.hourglass_empty,
      title: '',
    );
  }

  /// Convenience loading spinner without an icon/title block.
  static Widget loadingBody() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty && onRetry == null && subtitle == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Branded stand-in for Flutter's red [ErrorWidget] screen in release.
class AppErrorContainer extends StatelessWidget {
  const AppErrorContainer({super.key, this.details});

  final FlutterErrorDetails? details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightBackground,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pets,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'VauVau',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Došlo je do greške. Pokušajte ponovo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
                if (kDebugMode && details != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    details!.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint('🔴 STACK: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error: $error');
    debugPrint('$stack');
    return true;
  };

  ErrorWidget.builder = (details) {
    if (kReleaseMode) {
      return AppErrorContainer(details: details);
    }
    return ErrorWidget(details.exception);
  };
}
