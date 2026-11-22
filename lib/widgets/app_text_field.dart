import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A label above a white rounded field, as in the design. With [maxLength]
/// a small "46 / 200" counter sits inside the field's bottom-right corner.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.trailingLabel,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;

  /// Small text on the right of the label, e.g. "Optional".
  final String? trailingLabel;
  final int maxLines;
  final int? maxLength;
  final bool obscureText;

  /// Off for usernames and the like.
  final bool autocorrect;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines > 1 ? maxLines : null,
      maxLength: maxLength,
      obscureText: obscureText,
      autocorrect: autocorrect && !obscureText,
      enableSuggestions: autocorrect && !obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      style: maxLines > 1
          ? AppText.note(color: AppColors.ink).copyWith(height: 1.43)
          : AppText.body(),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: (maxLines > 1 ? AppText.note() : AppText.body())
            .copyWith(color: AppColors.faint),
        // The design draws its own counter inside the field.
        counterText: '',
        contentPadding: EdgeInsets.fromLTRB(
          14,
          maxLines > 1 ? 12 : 13,
          14,
          maxLength != null ? 24 : 13,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.labelMedium())),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: AppText.meta(color: AppColors.faint)
                    .copyWith(fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (maxLength == null)
          field
        else
          Stack(
            children: [
              field,
              Positioned(
                right: 14,
                bottom: 8,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => Text(
                    '${value.text.characters.length} / $maxLength',
                    style: AppText.meta(color: AppColors.faint)
                        .copyWith(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
