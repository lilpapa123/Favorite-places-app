import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum PillButtonVariant { filled, outlined, soft }

/// Rounded, friendly button. Filled = main action, outlined = secondary,
/// soft = tinted background (used for small round icon buttons too).
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.filled,
    this.icon,
    this.leading,
    this.expanded = false,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;

  /// A design icon shown before the label (used instead of [icon]).
  final Widget? leading;
  final bool expanded;

  /// 52 px tall instead of 44 — for the form's main "Save place" action.
  final bool large;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border) = switch (widget.variant) {
      PillButtonVariant.filled => (
        _enabled
            ? (_pressed ? AppColors.accentPressed : AppColors.accent)
            : AppColors.accentDisabled,
        AppColors.surface,
        null,
      ),
      PillButtonVariant.outlined => (
        _pressed ? AppColors.accentSoft : AppColors.surface,
        _enabled ? AppColors.accent : AppColors.accentDisabled,
        _enabled ? AppColors.accent : AppColors.accentDisabled,
      ),
      PillButtonVariant.soft => (
        _pressed ? const Color(0xFFF6D6CE) : AppColors.accentSoft,
        AppColors.accent,
        null,
      ),
    };

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.ease,
            height: widget.large ? 52 : 44,
            width: widget.expanded ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: border == null
                  ? null
                  : Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: widget.expanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: AppSpace.md),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: fg),
                  const SizedBox(width: AppSpace.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.button(
                      color: fg,
                      size: widget.large ? 16 : 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44 px round icon button, e.g. the heart on a place card.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.background = AppColors.accentSoft,
    this.foreground = AppColors.accent,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// A 44 px white circle holding a design icon: back, close, more, sort.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 44,
    this.background = AppColors.surface,
    this.shadow = false,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double size;
  final Color background;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: shadow ? AppShadow.soft : null,
        ),
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
