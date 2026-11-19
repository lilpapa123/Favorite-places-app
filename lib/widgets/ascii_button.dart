import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum AsciiButtonVariant { filled, outlined }

/// Square, 1px, mono, and it presses to 0.96 on the theme's stepped curve.
class AsciiButton extends StatefulWidget {
  const AsciiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AsciiButtonVariant.filled,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AsciiButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  @override
  State<AsciiButton> createState() => _AsciiButtonState();
}

class _AsciiButtonState extends State<AsciiButton> {
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
    final bool filled = widget.variant == AsciiButtonVariant.filled;
    final Color foreground = filled
        ? (_enabled ? AsciiPalette.accentInk : AsciiPalette.mute)
        : (_enabled ? AsciiPalette.accent : AsciiPalette.mute);
    final Color background = filled
        ? (_enabled ? AsciiPalette.accent : AsciiPalette.surfaceRaised)
        : Colors.transparent;
    final Color border = filled
        ? (_enabled ? AsciiPalette.accent : AsciiPalette.line)
        : AsciiPalette.lineStrong;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? AsciiMotion.pressScale : 1,
          duration: AsciiMotion.fast,
          curve: AsciiMotion.ease,
          child: Container(
            width: widget.expanded ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: AsciiShape.tapTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AsciiSpace.xl,
              vertical: AsciiSpace.md,
            ),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border, width: AsciiShape.borderWidth),
            ),
            child: Row(
              mainAxisSize: widget.expanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: foreground),
                  const SizedBox(width: AsciiSpace.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AsciiType.button(color: foreground),
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
