import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Single-choice "Type of place" chips: selected is terracotta, others white.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PlaceCategory selected;
  final ValueChanged<PlaceCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Type of place', style: AppText.labelMedium()),
        const SizedBox(height: 6),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final category in PlaceCategory.values)
              ChoicePill(
                label: category.label,
                selected: category == selected,
                onTap: () => onSelected(category),
              ),
          ],
        ),
      ],
    );
  }
}

/// A 36 px pill used for type chips and the My places filters.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppText.labelMedium(
              color: selected ? AppColors.surface : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
