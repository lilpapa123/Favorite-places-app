import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The theme's terminal caret. Stops blinking when the platform asks for
/// reduced motion so the UI stays fully usable.
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({
    super.key,
    this.width = 8,
    this.height = 18,
    this.color = AsciiPalette.accent,
  });

  final double width;
  final double height;
  final Color color;

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AsciiMotion.blink,
  );

  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: const StepsCurve(2)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ColoredBox(color: widget.color),
      ),
    );
  }
}
