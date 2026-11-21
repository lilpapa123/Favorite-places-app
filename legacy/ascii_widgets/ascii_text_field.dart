import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A terminal-style input: `$` prompt, 1px rule, accent on focus.
class AsciiTextField extends StatefulWidget {
  const AsciiTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  State<AsciiTextField> createState() => _AsciiTextFieldState();
}

class _AsciiTextFieldState extends State<AsciiTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) {
      return;
    }
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AsciiMotion.fast,
      curve: AsciiMotion.ease,
      padding: const EdgeInsets.symmetric(
        horizontal: AsciiSpace.md,
        vertical: AsciiSpace.md,
      ),
      decoration: BoxDecoration(
        color: AsciiPalette.surface,
        border: Border.all(
          color: _focused ? AsciiPalette.accent : AsciiPalette.line,
          width: AsciiShape.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Text('\$', style: AsciiType.body(color: AsciiPalette.accent)),
          const SizedBox(width: AsciiSpace.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              obscureText: widget.obscureText,
              autocorrect: !widget.obscureText,
              enableSuggestions: !widget.obscureText,
              keyboardType: widget.keyboardType,
              autofillHints: widget.autofillHints,
              maxLines: 1,
              style: AsciiType.body(),
              cursorColor: AsciiPalette.accent,
              cursorWidth: 2,
              cursorRadius: Radius.zero,
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: AsciiType.body(color: AsciiPalette.mute),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
