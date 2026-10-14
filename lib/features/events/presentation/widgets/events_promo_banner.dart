import 'package:flutter/material.dart';

import '../events_screen.dart';
import '../events_strings.dart';

class EventsPromoBanner extends StatelessWidget {
  const EventsPromoBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2E7D32),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EventsScreen()),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              Icon(Icons.event_available, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  compact ? EventsStrings.mapBanner : EventsStrings.banner,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
