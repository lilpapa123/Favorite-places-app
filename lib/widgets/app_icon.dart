import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// One of the design's icons from `assets/icons/<name>.svg`.
///
/// Each SVG keeps the color it has in the Figma file; pass [color] to tint it
/// (e.g. a tab icon turning terracotta when selected).
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size, this.color});

  final String name;

  /// Defaults to the SVG's own size from the design.
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
