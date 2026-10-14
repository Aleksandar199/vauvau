import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/walk_record.dart';
import '../map_strings.dart';
import '../walk_history_controller.dart';

Future<void> showWalkHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _WalkHistorySheet(),
  );
}

class _WalkHistorySheet extends ConsumerWidget {
  const _WalkHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walkHistoryProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                MapStrings.walkHistoryTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                MapStrings.walkHistoryLastDays,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: async.when(
                  loading: () =>
                      Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Text(MapStrings.walkHistoryEmpty),
                  ),
                  data: (walks) {
                    if (walks.isEmpty) {
                      return Center(
                        child: Text(MapStrings.walkHistoryEmpty),
                      );
                    }
                    final totalSeconds = walks.fold<int>(
                      0,
                      (sum, walk) => sum + walk.durationSeconds,
                    );
                    final totalKm = walks.fold<double>(
                      0,
                      (sum, walk) => sum + walk.distanceKm,
                    );
                    final days = _groupByDay(walks);
                    return ListView(
                      controller: scrollController,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SummaryTile(
                                  label: MapStrings.walkHistoryTotal,
                                  value: _formatDuration(totalSeconds),
                                ),
                              ),
                              Expanded(
                                child: _SummaryTile(
                                  label: MapStrings.walkDistance,
                                  value: '${totalKm.toStringAsFixed(2)} km',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final day in days) ...[
                          Text(
                            day.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          for (final walk in day.walks)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.directions_walk),
                                title: Text(
                                  '${walk.durationLabel} · ${walk.distanceLabel}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  walk.statusMessage.trim().isEmpty
                                      ? _timeRange(walk)
                                      : '${walk.statusMessage} · ${_timeRange(walk)}',
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_DayGroup> _groupByDay(List<WalkRecord> walks) {
    final map = <String, _DayGroup>{};
    for (final walk in walks) {
      final key =
          '${walk.endedAt.year}-${walk.endedAt.month}-${walk.endedAt.day}';
      final group = map.putIfAbsent(
        key,
        () => _DayGroup(label: _dayLabel(walk.endedAt), walks: []),
      );
      group.walks.add(walk);
    }
    return map.values.toList();
  }

  String _dayLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    if (day == today) return 'Danas';
    if (day == today.subtract(const Duration(days: 1))) return 'Juče';
    return '${value.day}.${value.month}.${value.year}.';
  }

  String _timeRange(WalkRecord walk) {
    String t(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${t(walk.startedAt)} – ${t(walk.endedAt)}';
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _DayGroup {
  _DayGroup({required this.label, required this.walks});

  final String label;
  final List<WalkRecord> walks;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF166534),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
