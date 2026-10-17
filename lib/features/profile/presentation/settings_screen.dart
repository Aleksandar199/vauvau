import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/theme/app_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_preference.dart';
import '../../legal/presentation/legal_document_screen.dart';
import '../../legal/presentation/legal_strings.dart';
import '../../moderation/presentation/blocked_users_screen.dart';
import '../../moderation/presentation/moderation_strings.dart';
import '../../notifications/data/push_platform.dart';
import '../../notifications/presentation/push_controller.dart';
import '../domain/app_settings.dart';
import 'matching_filters_sheet.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const double _minRadius = 1;
  static const double _maxRadius = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final radius = ref.watch(matchingFiltersProvider).radiusKm;
    final pushGranted = ref.watch(pushControllerProvider);
    void edit(AppSettings Function(AppSettings current) change) {
      ref
          .read(appSettingsProvider.notifier)
          .update(change(ref.read(appSettingsProvider)));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(ProfileStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SectionLabel(ProfileStrings.notifications),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: pushGranted
                    ? Icons.notifications_active
                    : Icons.notifications_none_rounded,
                title: ProfileStrings.enableNotifications,
                subtitle: pushGranted
                    ? ProfileStrings.notificationsGranted
                    : ProfileStrings.enableNotificationsHint,
                trailing: pushGranted
                    ? const Icon(Icons.check_circle, color: Color(0xFF15803D))
                    : const Icon(Icons.chevron_right),
                onTap: () => _enableNotifications(context, ref),
              ),
              _SettingsSwitch(
                icon: Icons.directions_walk_rounded,
                title: ProfileStrings.notifyWalks,
                subtitle: ProfileStrings.notifyWalksHint,
                value: settings.notifyWalkRequests,
                onChanged: (value) =>
                    edit((s) => s.copyWith(notifyWalkRequests: value)),
              ),
              _SettingsSwitch(
                icon: Icons.chat_bubble_outline_rounded,
                title: ProfileStrings.notifyMessages,
                subtitle: ProfileStrings.notifyMessagesHint,
                value: settings.notifyMessages,
                onChanged: (value) =>
                    edit((s) => s.copyWith(notifyMessages: value)),
              ),
              _SettingsSwitch(
                icon: Icons.favorite_border_rounded,
                title: ProfileStrings.notifyMatches,
                subtitle: ProfileStrings.notifyMatchesHint,
                value: settings.notifyNewMatches,
                onChanged: (value) =>
                    edit((s) => s.copyWith(notifyNewMatches: value)),
              ),
            ],
          ),
          SizedBox(height: 20),
          _SectionLabel(ProfileStrings.appearance),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TileIcon(Icons.palette_outlined),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ProfileStrings.appearance,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                ProfileStrings.appearanceHint,
                                style: _subtitleStyle(theme),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(ProfileStrings.themeDark),
                          selected: settings.themePreference ==
                              AppThemePreference.dark,
                          onSelected: (_) => ref
                              .read(appSettingsProvider.notifier)
                              .setThemePreference(AppThemePreference.dark),
                        ),
                        ChoiceChip(
                          label: Text(ProfileStrings.themeLight),
                          selected: settings.themePreference ==
                              AppThemePreference.light,
                          onSelected: (_) => ref
                              .read(appSettingsProvider.notifier)
                              .setThemePreference(AppThemePreference.light),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _SectionLabel(ProfileStrings.language),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TileIcon(Icons.language_rounded),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ProfileStrings.language,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                ProfileStrings.languageHint,
                                style: _subtitleStyle(theme),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(ProfileStrings.languageSerbian),
                          selected: settings.language == AppLanguage.serbian,
                          onSelected: (_) => ref
                              .read(appSettingsProvider.notifier)
                              .setLanguage(AppLanguage.serbian),
                        ),
                        ChoiceChip(
                          label: Text(ProfileStrings.languageEnglish),
                          selected: settings.language == AppLanguage.english,
                          onSelected: (_) => ref
                              .read(appSettingsProvider.notifier)
                              .setLanguage(AppLanguage.english),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _SectionLabel(ProfileStrings.searchAndMap),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TileIcon(Icons.radar_rounded),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            ProfileStrings.radiusFilter,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            ProfileStrings.radiusValue(radius),
                            style: const TextStyle(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 54, top: 2),
                      child: Text(
                        ProfileStrings.radiusHint,
                        style: _subtitleStyle(theme),
                      ),
                    ),
                    Slider(
                      min: _minRadius,
                      max: _maxRadius,
                      divisions: (_maxRadius - _minRadius).round(),
                      label: ProfileStrings.radiusValue(radius),
                      value: radius.clamp(_minRadius, _maxRadius).toDouble(),
                      onChanged: (value) =>
                          edit((s) => s.copyWith(radiusKm: value)),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.tune_rounded,
                title: ProfileStrings.searchFilters,
                subtitle: ProfileStrings.searchFiltersHint,
                onTap: () => showMatchingFiltersSheet(context),
              ),
              _SettingsSwitch(
                icon: Icons.location_on_outlined,
                title: ProfileStrings.showLocation,
                subtitle: ProfileStrings.showLocationHint,
                value: settings.showLocationOnMap,
                onChanged: (value) =>
                    edit((s) => s.copyWith(showLocationOnMap: value)),
              ),
            ],
          ),
          SizedBox(height: 20),
          _SectionLabel(ModerationStrings.blockedUsers),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.block_outlined,
                title: ModerationStrings.blockedUsers,
                subtitle: ModerationStrings.blockedUsersHint,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BlockedUsersScreen(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _SectionLabel(LegalStrings.sectionTitle),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: LegalStrings.privacyPolicy,
                subtitle: LegalStrings.privacySubtitle,
                onTap: () => openLegalDocument(
                  context,
                  kind: LegalDocumentKind.privacy,
                ),
              ),
              _SettingsTile(
                icon: Icons.gavel_outlined,
                title: LegalStrings.termsOfService,
                subtitle: LegalStrings.termsSubtitle,
                onTap: () => openLegalDocument(
                  context,
                  kind: LegalDocumentKind.terms,
                ),
              ),
            ],
          ),
          SizedBox(height: 28),
          Center(
            child: Text(
              ProfileStrings.appVersion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableNotifications(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!isFirebaseReady || !isPushPlatform) {
      messenger.showSnackBar(
        SnackBar(content: Text(ProfileStrings.notificationsUnsupported)),
      );
      return;
    }
    if (ref.read(pushControllerProvider)) {
      messenger.showSnackBar(
        SnackBar(content: Text(ProfileStrings.notificationsGranted)),
      );
      return;
    }
    final settingsCtrl = ref.read(appSettingsProvider.notifier);
    final granted = await ref
        .read(pushControllerProvider.notifier)
        .requestPermission();
    settingsCtrl.update(
      ref.read(appSettingsProvider).copyWith(pushPrompted: true),
    );
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? ProfileStrings.notificationsGranted
              : ProfileStrings.notificationsDenied,
        ),
      ),
    );
  }
}

TextStyle? _subtitleStyle(ThemeData theme) {
  return theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
    height: 1.3,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
    );
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppCardTokens.borderRadius,
        boxShadow: AppCardTokens.softShadow(),
      ),
      child: Material(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: AppCardTokens.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) divider,
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _TileIcon(icon),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle, style: _subtitleStyle(theme)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: _TileIcon(icon),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle, style: _subtitleStyle(theme)),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
