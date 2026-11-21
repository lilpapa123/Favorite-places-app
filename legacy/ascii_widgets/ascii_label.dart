import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A `// section` caption in the theme's code voice.
class AsciiLabel extends StatelessWidget {
  const AsciiLabel(this.text, {super.key, this.color = AsciiPalette.mute});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '// $text',
      style: AsciiType.label(color: color),
      textAlign: TextAlign.left,
    );
  }
}
