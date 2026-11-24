import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Big page title with a quiet subtitle and optional round actions on the
/// left and right: "My places / 3 favorite places".
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.titleIsUsername = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// One left-to-right line, shrunk to fit: in Arabic "khalid." would
  /// otherwise read ".khalid", and 20 wide letters don't fit at full size.
  final bool titleIsUsername;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.page,
        AppSpace.sm,
        AppSpace.page,
        AppSpace.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: leading!,
            ),
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titleIsUsername)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textDirection: TextDirection.ltr,
                      style: AppText.heading(),
                    ),
                  )
                else
                  Text(title, style: AppText.heading()),
                if (subtitle != null)
                  Text(subtitle!, style: AppText.meta().copyWith(height: 1.4)),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// Bottom padding that clears the floating glass tab bar.
double bottomBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + AppSpace.xxl;
