import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AsciiTab {
  const AsciiTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Bottom navigation in the theme's voice: square, 1px top rule, accent bar
/// over the selected tab, and a filled `+ add` block in the middle that runs
/// an action instead of switching tabs.
class AsciiTabBar extends StatelessWidget {
  const AsciiTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    this.addSlot = 2,
  });

  final List<AsciiTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  /// Where the add button sits among the tabs (0 = before the first tab).
  final int addSlot;

  static const double _height = 58;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tabs.length; i++) {
      if (i == addSlot) {
        children.add(Expanded(child: _AddButton(onTap: onAdd)));
      }
      children.add(
        Expanded(
          child: _TabButton(
            tab: tabs[i],
            selected: i == currentIndex,
            onTap: () => onSelect(i),
          ),
        ),
      );
    }
    if (addSlot >= tabs.length) {
      children.add(Expanded(child: _AddButton(onTap: onAdd)));
    }

    return Container(
      decoration: const BoxDecoration(
        color: AsciiPalette.canvas,
        border: Border(
          top: BorderSide(
            color: AsciiPalette.line,
            width: AsciiShape.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(height: _height, child: Row(children: children)),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AsciiTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AsciiPalette.accent : AsciiPalette.mute;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: AsciiMotion.fast,
              curve: AsciiMotion.ease,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AsciiSpace.md),
              color: selected ? AsciiPalette.accent : Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: 20, color: color),
                  const SizedBox(height: AsciiSpace.xxs),
                  Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AsciiType.meta(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'add place',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AsciiSpace.sm),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AsciiPalette.accent,
              border: Border.all(
                color: AsciiPalette.accent,
                width: AsciiShape.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: AsciiPalette.accentInk),
                const SizedBox(width: AsciiSpace.xxs),
                Text(
                  'add',
                  style: AsciiType.button(color: AsciiPalette.accentInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
