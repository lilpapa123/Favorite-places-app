import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';

/// Empty state for the feed: pin icon, friendly copy, one clear action.
class EmptyPlaces extends StatelessWidget {
  const EmptyPlaces({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place_outlined,
              size: 44,
              color: AppColors.faint,
            ),
            const SizedBox(height: AppSpace.md),
            Text(context.l10n.noFavoritesYet, style: AppText.title()),
            const SizedBox(height: AppSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                context.l10n.noFavoritesBody,
                textAlign: TextAlign.center,
                style: AppText.body(color: AppColors.muted)
                    .copyWith(fontSize: 14),
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: AppSpace.lg),
              PillButton(label: context.l10n.addAPlace, onPressed: onAdd),
            ],
          ],
        ),
      ),
    );
  }
}
