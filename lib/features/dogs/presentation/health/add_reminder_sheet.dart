import 'package:flutter/material.dart';

import '../../domain/dog_reminder.dart';
import 'reminder_form_sheet.dart';
import 'reminder_strings.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

typedef ReminderDogOption = ({String id, String name});

Future<void> showAddReminderTypeSheet({
  required BuildContext context,
  required List<ReminderDogOption> dogs,
  String? preferredDogId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _AddReminderTypeSheet(
        dogs: dogs,
        preferredDogId: preferredDogId,
      );
    },
  );
}

class _AddReminderTypeSheet extends StatelessWidget {
  const _AddReminderTypeSheet({
    required this.dogs,
    this.preferredDogId,
  });

  final List<ReminderDogOption> dogs;
  final String? preferredDogId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              ReminderStrings.chooseTypeTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (final category in ReminderCategory.values) ...[
              Text(
                _categoryTitle(category),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 8),
              for (final type in ReminderStrings.typesFor(category))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await showReminderFormSheet(
                          context: context,
                          dogs: dogs,
                          preferredDogId: preferredDogId,
                          type: type,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          ReminderStrings.typeLabel(type),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  String _categoryTitle(ReminderCategory category) {
    return switch (category) {
      ReminderCategory.health => ReminderStrings.catHealth,
      ReminderCategory.care => ReminderStrings.catCare,
      ReminderCategory.food => ReminderStrings.catFood,
      ReminderCategory.other => ReminderStrings.catOther,
    };
  }
}
