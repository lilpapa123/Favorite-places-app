import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/ascii_panel.dart';
import 'package:flutter/material.dart';

/// Empty state for the feed — terse, framed, no grey box.
class EmptyPlaces extends StatelessWidget {
  const EmptyPlaces({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AsciiSpace.lg),
        child: AsciiPanel(
          label: 'empty',
          padding: const EdgeInsets.symmetric(
            horizontal: AsciiSpace.xl,
            vertical: AsciiSpace.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('no places yet', style: AsciiType.heading()),
              const SizedBox(height: AsciiSpace.sm),
              Text(
                'add one below to start\nyour collection.',
                textAlign: TextAlign.center,
                style: AsciiType.small(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
