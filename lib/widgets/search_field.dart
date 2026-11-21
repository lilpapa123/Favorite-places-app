import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// White 48 px search box with the design's magnifier icon.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.shadow = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.fieldAll,
        boxShadow: shadow ? AppShadow.soft : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const AppIcon('search'),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppText.body(),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppText.body(color: AppColors.faint),
                filled: false,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: 14)
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(
                      Icons.cancel,
                      size: 18,
                      color: AppColors.faint,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
